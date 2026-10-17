import 'package:flutter_test/flutter_test.dart';

import 'package:awan/features/prayer_engine/domain/entities/adhan_sound.dart';

/// The clip a reader picks, and where that choice sends the notification.
///
/// A channel's sound is frozen at creation, so the *only* thing that can change
/// which sound rings is the channel id. That makes these ids behaviour, not
/// naming: if they drift, the reader's choice silently reverts to a stale clip.
void main() {
  group('AdhanSound storage', () {
    test('every choice round trips through its stored value', () {
      for (final AdhanSound sound in AdhanSound.values) {
        expect(AdhanSound.fromWire(sound.wire), sound);
      }
    });

    test('an unknown or missing value means the system tone, never silence', () {
      // A hand-edited preference or a value from a newer build must not leave the
      // adhan mute without the reader asking for that.
      expect(AdhanSound.fromWire(null), AdhanSound.system);
      expect(AdhanSound.fromWire(''), AdhanSound.system);
      expect(AdhanSound.fromWire('beep'), AdhanSound.system);
    });

    test('the wire values are stable text, not indices', () {
      expect(AdhanSound.system.wire, 'system');
      expect(AdhanSound.silent.wire, 'silent');
      expect(AdhanSound.takbir.rawResource, 'allah_akbar');
      expect(AdhanSound.call.rawResource, 'aser_ela_khaleky');
      expect(AdhanSound.adhan.rawResource, 'azan_salah');
      expect(AdhanSound.ring.rawResource, 'nokia_notification');
    });
  });

  group('audibility', () {
    test('only silent is inaudible', () {
      expect(AdhanSound.silent.audible, isFalse);
      for (final AdhanSound sound in AdhanSound.values) {
        if (sound == AdhanSound.silent) continue;
        expect(sound.audible, isTrue, reason: sound.wire);
      }
    });

    test('the bundled clips are exactly the ones shipped in res/raw', () {
      expect(AdhanSound.bundled, <AdhanSound>[
        AdhanSound.takbir,
        AdhanSound.call,
        AdhanSound.adhan,
        AdhanSound.ring,
      ]);
      for (final AdhanSound sound in AdhanSound.bundled) {
        expect(sound.rawResource, isNotNull);
      }
      expect(AdhanSound.system.rawResource, isNull);
      expect(AdhanSound.silent.rawResource, isNull);
    });
  });

  group('channel ids', () {
    test('a bundled clip gets its own channel, so changing it can take effect', () {
      expect(AdhanSound.adhan.adhanChannelId(), 'awan.adhan.s-adhan');
      expect(AdhanSound.takbir.adhanChannelId(), 'awan.adhan.s-takbir');
      expect(AdhanSound.call.reminderChannelId(), 'awan.adhan.reminder.s-call');
    });

    test('the two non-bundled choices keep the ids already in use', () {
      // Renaming these would abandon channels that devices already have, and a
      // channel that exists is what fixes an alert's sound.
      expect(AdhanSound.system.adhanChannelId(), 'awan.adhan-v2');
      expect(AdhanSound.system.reminderChannelId(), 'awan.adhan.reminder.sound');
      expect(AdhanSound.silent.adhanChannelId(), AdhanSound.quietChannelId);
      expect(AdhanSound.silent.reminderChannelId(), 'awan.adhan.reminder-v2');
    });

    test('the adhan and the reminder never share a channel', () {
      for (final AdhanSound sound in AdhanSound.values) {
        expect(sound.adhanChannelId(), isNot(sound.reminderChannelId()),
            reason: sound.wire);
      }
    });

    test('every id the enum can ask for is listed for creation', () {
      final Set<String> ids = AdhanSound.allChannelIds;
      for (final AdhanSound sound in AdhanSound.values) {
        expect(ids, contains(sound.adhanChannelId()));
        expect(ids, contains(sound.reminderChannelId()));
      }
      // The count follows the clips: one adhan channel and one reminder channel
      // per choice, less whichever pairs the implementation shares.
      final Set<String> requested = <String>{
        for (final AdhanSound sound in AdhanSound.values) ...<String>[
          sound.adhanChannelId(),
          sound.reminderChannelId(),
        ],
      };
      expect(ids.length, requested.length);
    });
  });
}
