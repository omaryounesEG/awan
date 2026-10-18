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

  /// «الله أكبر» — the takbir opening.
  takbir('allah_akbar', 'takbir', 'allah_akbar'),

  /// «أسرع على خالقك» — a short call.
  call('aser_ela_khaleky', 'call', 'aser_ela_khaleky'),

  /// «أذان الصلاة» — the full adhan.
  adhan('azan_salah', 'adhan', 'azan_salah'),

  /// A plain ringtone, no voice: for a phone that should *tell* you it is
  /// prayer time without reciting the adhan in a meeting.
  ring('nokia_notification', 'ring', 'nokia_notification');

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
    takbir,
    call,
    adhan,
    ring,
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
