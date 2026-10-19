// In extension type, implements doesn't require manually re-implementing all members of the
// underlying type.

/// A floating-point number constrained to the closed unit interval [0.0, 1.0].
extension type const UnitInterval(double value) implements double {
  this : assert(value >= 0.0 && value <= 1.0, 'UnitInterval must be between 0.0 and 1.0');

  /// Creates a [UnitInterval] safely by clamping [raw] into [0.0, 1.0].
  new clamped(double raw) : this(raw.clamp(0.0, 1.0));

  /// Converts the interval to an integer percentage from 0 to 100.
  int get asPercent => (value * 100).round();
}
