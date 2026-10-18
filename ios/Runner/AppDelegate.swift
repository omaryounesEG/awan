import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Held so the channel handlers outlive `didFinishLaunching`.
  private var awanChannels: AwanPlatformChannels?
  private var recitationAudio: AwanRecitationAudio?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      awanChannels = AwanPlatformChannels(messenger: controller.binaryMessenger)

      let audio = AwanRecitationAudio()
      FlutterEventChannel(
        name: "com.awan.app/recitation/audio",
        binaryMessenger: controller.binaryMessenger
      ).setStreamHandler(audio)
      recitationAudio = audio
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// The iOS side of the two channels the Android build implements in Kotlin.
///
/// Deliberately in this file: a new Swift file has to be added to the Xcode
/// target by hand, and a file that actually builds is worth more than a tidy
/// folder that silently never gets compiled.
///
/// Only what can honestly work on iOS is registered. The ringer-window channel,
/// the adhan preview from `res/raw`, the APK updater and the on-device
/// embeddings are Android-shaped: their Dart callers already degrade to a no-op
/// when the channel is absent, so they stay absent.
final class AwanPlatformChannels: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var pendingPermission: FlutterResult?
  private var pendingFix: FlutterResult?
  private var fixTimeout: DispatchWorkItem?

  /// The fix is a single bounded request — `requestLocation` stops the radio by
  /// itself. No continuous updates, no background mode, no always-authorisation.
  private static let fixTimeoutSeconds: TimeInterval = 12

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

    let location = FlutterMethodChannel(name: "awan/location", binaryMessenger: messenger)
    location.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "channel released", details: nil))
        return
      }
      switch call.method {
      case "hasPermission":
        result(self.hasPermission())
      case "requestPermission":
        self.requestPermission(result)
      case "isServiceEnabled":
        result(CLLocationManager.locationServicesEnabled())
      case "openLocationSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      case "getLocation":
        self.deliverFix(result)
      case "timeZoneId":
        result(TimeZone.current.identifier)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let clock = FlutterMethodChannel(name: "awan/clock", binaryMessenger: messenger)
    clock.setMethodCallHandler { call, result in
      switch call.method {
      case "keepScreenOn":
        let arguments = call.arguments as? [String: Any]
        UIApplication.shared.isIdleTimerDisabled = (arguments?["on"] as? Bool) ?? false
        result(nil)
      default:
        // `postCard` is the Android countdown notification. iOS has no card that
        // dismisses itself without a notification service extension, and the
        // prayer screen already shows the same countdown.
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Permission

  private func hasPermission() -> Bool {
    let status = locationManager.authorizationStatus
    return status == .authorizedWhenInUse || status == .authorizedAlways
  }

  private func requestPermission(_ result: @escaping FlutterResult) {
    if locationManager.authorizationStatus == .notDetermined {
      pendingPermission = result
      locationManager.requestWhenInUseAuthorization()
      return
    }
    result(hasPermission())
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager.authorizationStatus != .notDetermined,
          let pending = pendingPermission else { return }
    pendingPermission = nil
    pending(hasPermission())
  }

  // MARK: - One fix

  private func deliverFix(_ result: @escaping FlutterResult) {
    if pendingFix != nil {
      // A second tap while the first request is in flight: answer it plainly
      // rather than queueing another radio wake-up.
      result(nil)
      return
    }
    guard hasPermission(), CLLocationManager.locationServicesEnabled() else {
      result(nil)
      return
    }
    if let cached = locationManager.location,
       cached.timestamp.timeIntervalSinceNow > -300 {
      result(payload(for: cached))
      return
    }

    pendingFix = result
    locationManager.requestLocation()

    let timeout = DispatchWorkItem { [weak self] in
      guard let self = self, let pending = self.pendingFix else { return }
      self.pendingFix = nil
      pending(nil)
    }
    fixTimeout = timeout
    DispatchQueue.main.asyncAfter(
      deadline: .now() + AwanPlatformChannels.fixTimeoutSeconds,
      execute: timeout
    )
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    finishFix(locations.last)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishFix(nil)
  }

  private func finishFix(_ location: CLLocation?) {
    fixTimeout?.cancel()
    fixTimeout = nil
    guard let pending = pendingFix else { return }
    pendingFix = nil
    pending(location.map(payload(for:)))
  }

  private func payload(for location: CLLocation) -> [String: Any] {
    [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy,
    ]
  }
}

/// The microphone for the recitation checker: 16 kHz mono 16-bit PCM, live.
///
/// Whisper was trained at that rate, and resampling inside Dart would throw
/// away the high frequencies that separate ص from س — so the conversion happens
/// once, here, with `AVAudioConverter`, and the bytes go straight to the stream.
///
/// Nothing is written to disk and nothing runs while the screen is closed: the
/// engine starts on `onListen` and stops on `onCancel`, and that is the whole
/// lifetime.
final class AwanRecitationAudio: NSObject, FlutterStreamHandler {
  private let engine = AVAudioEngine()
  private var sink: FlutterEventSink?
  private var converter: AVAudioConverter?
  private var targetFormat: AVAudioFormat?
  private var running = false

  static let sampleRate: Double = 16000

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    do {
      try start()
      return nil
    } catch {
      sink = nil
      return FlutterError(
        code: "audio_start_failed",
        message: error.localizedDescription,
        details: nil
      )
    }
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stop()
    return nil
  }

  private func start() throws {
    guard !running else { return }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
    try session.setPreferredSampleRate(AwanRecitationAudio.sampleRate)
    try session.setActive(true)

    let input = engine.inputNode
    let hardwareFormat = input.inputFormat(forBus: 0)
    guard hardwareFormat.sampleRate > 0, hardwareFormat.channelCount > 0 else {
      throw NSError(
        domain: "awan.recitation",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "no microphone input available"]
      )
    }
    guard let target = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: AwanRecitationAudio.sampleRate,
      channels: 1,
      interleaved: true
    ), let audioConverter = AVAudioConverter(from: hardwareFormat, to: target) else {
      throw NSError(
        domain: "awan.recitation",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "cannot convert the microphone format"]
      )
    }

    converter = audioConverter
    targetFormat = target

    input.installTap(onBus: 0, bufferSize: 3200, format: hardwareFormat) { [weak self] buffer, _ in
      self?.emit(buffer)
    }

    engine.prepare()
    try engine.start()
    running = true
  }

  private func emit(_ buffer: AVAudioPCMBuffer) {
    guard let sink = sink,
          let audioConverter = converter,
          let target = targetFormat else { return }

    let ratio = target.sampleRate / buffer.format.sampleRate
    let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
    guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { return }

    var supplied = false
    var conversionError: NSError?
    audioConverter.convert(to: output, error: &conversionError) { _, status in
      if supplied {
        status.pointee = .noDataNow
        return nil
      }
      supplied = true
      status.pointee = .haveData
      return buffer
    }

    if conversionError != nil { return }
    guard output.frameLength > 0, let channels = output.int16ChannelData else { return }

    let count = Int(output.frameLength) * MemoryLayout<Int16>.size
    let data = Data(bytes: channels[0], count: count)
    DispatchQueue.main.async {
      sink(FlutterStandardTypedData(bytes: data))
    }
  }

  private func stop() {
    sink = nil
    guard running else { return }
    running = false
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    converter = nil
    targetFormat = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }
}
