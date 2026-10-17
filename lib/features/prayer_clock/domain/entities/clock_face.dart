/// The look of the prayer clock's digits.
///
/// A face is not a theme: the reader picks a *glow* (the three modern colours)
/// or the cut-segment look, and day/night is a separate switch — the lock screen
/// is dark, the wall clock in a lit room is not, and neither choice implies the
/// other.
enum ClockFace {
  segment('segment'),
  white('white'),
  red('red'),
  green('green');

  const ClockFace(this.wire);

  /// Stable value for storage; never derive it from `index`.
  final String wire;

  static ClockFace fromWire(String? value) => ClockFace.values.firstWhere(
        (ClockFace face) => face.wire == value,
        orElse: () => ClockFace.segment,
      );
}
