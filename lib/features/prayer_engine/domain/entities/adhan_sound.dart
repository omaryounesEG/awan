/// Which sound an alert plays.
///
/// The three ready-made clips ship **inside the APK** as Android raw resources,
/// not as Flutter assets: a notification's sound is read by the *system*, which
/// knows nothing about Flutter's asset bundle, so `res/raw` is the only place a
/// bundled clip can live and still ring.
///
/// A channel's sound is frozen the moment the channel is created, and later edits
/// are ignored — so the choice cannot be a property of one channel. Each audible
/// clip gets its own channel id, and the notification is posted on the channel
/// that matches the reader's choice.
enum AdhanSound {
  /// The phone's own alarm tone.
  system('system', 'system', null),

  /// Nothing at all — the notification still shows.
  silent('silent', 'silent', null),

  /// «أذان ١» — a full call to prayer.
  adhanOne('adhan_1', 'adhan1', 'adhan_1'),

  /// «أذان ٢» — a second full call, a different voice.
  adhanTwo('adhan_2', 'adhan2', 'adhan_2'),

  /// «تنبيه ١» — a short alert rather than a recitation.
  tanbihOne('tanbih_1', 'tanbih1', 'tanbih_1'),

  /// «تنبيه ٢» — a brief chime.
  tanbihTwo('tanbih_2', 'tanbih2', 'tanbih_2'),

  /// «تنبيه ٣» — the longest of the three alerts.
  tanbihThree('tanbih_3', 'tanbih3', 'tanbih_3');

  const AdhanSound(this.wire, this.key, this.rawResource);

  /// Stored in preferences. Never an index: reordering this enum must not
  /// silently repaint the reader's choice.
  final String wire;

  /// Short key used inside channel ids, kept ascii and stable.
  final String key;

  /// The `res/raw` name on Android, or null for the two non-bundled choices.
  final String? rawResource;

  /// Whether this choice makes a sound at all.
  bool get audible => this != AdhanSound.silent;

  /// The clip as iOS names it: a file inside the app bundle, not a Flutter
  /// asset. iOS truncates a notification sound at 30 seconds, so the copies in
  /// `ios/Runner/Sounds` are trimmed to 28 s on purpose.
  String? get darwinSoundName =>
      rawResource == null ? null : '$rawResource.wav';

  /// The clips the reader can audition, in the order they are offered.
  static const List<AdhanSound> bundled = <AdhanSound>[
    adhanOne,
    adhanTwo,
    tanbihOne,
    tanbihTwo,
    tanbihThree,
  ];

  /// A stored value back to a choice. An unknown or missing value is the system
  /// tone, so a hand-edited preference cannot leave an alert mute.
  static AdhanSound fromWire(String? wire) {
    for (final AdhanSound sound in AdhanSound.values) {
      if (sound.wire == wire) return sound;
    }
    return AdhanSound.system;
  }

  // ------------------------------------------------------------- channel ids
  //
  // One family for the adhan, one for the reminder before it: the two alerts are
  // planned separately and the reader may want a clip for one and silence for the
  // other.

  /// The phone's own alarm tone, used when the choice is [system].
  ///
  /// These are the ids the app has always used; the `-v2` suffixes are
  /// load-bearing, because Android freezes a channel's sound at creation (see
  /// [NotificationService]).
  static const String systemAdhanChannelId = 'awan.adhan-v2';
  static const String systemReminderChannelId = 'awan.adhan.reminder.sound';
  static const String silentReminderChannelId = 'awan.adhan.reminder-v2';
  static const String vibrateChannelId = 'awan.adhan.vibrate-v2';
  static const String quietChannelId = 'awan.adhan.quiet-v2';

  /// The channel that plays this clip for the adhan itself.
  String adhanChannelId() => rawResource == null
      ? (this == AdhanSound.silent ? quietChannelId : systemAdhanChannelId)
      : 'awan.adhan.s-$key';

  /// The channel that plays this clip for the reminder before the adhan.
  String reminderChannelId() => rawResource == null
      ? (this == AdhanSound.silent
          ? silentReminderChannelId
          : systemReminderChannelId)
      : 'awan.adhan.reminder.s-$key';

  /// Every channel this enum can ask for, so they can be created up front.
  static Set<String> get allChannelIds => <String>{
        for (final AdhanSound sound in AdhanSound.values) ...<String>[
          sound.adhanChannelId(),
          sound.reminderChannelId(),
        ],
      };
}
