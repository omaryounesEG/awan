import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Held so the channel handlers outlive `didFinishLaunching`.
  private var awanChannels: AwanPlatformChannels?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      awanChannels = AwanPlatformChannels(messenger: controller.binaryMessenger)
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
