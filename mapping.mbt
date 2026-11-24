///|
/// Errors never silently drop observations or degrade configured accuracy.
#derive(Debug, Eq)
pub(all) enum SketchError {
  InvalidAccuracy
  InvalidCapacity
  InvalidValue
  InvalidWeight
  InvalidQuantile
  CapacityExceeded
  CountOverflow
  IncompatibleConfig
  InvalidSnapshot
}

///|
/// Validated logarithmic mapping. Supports magnitudes in [1.0e-150, 1.0e150].
#derive(Debug)
pub struct Mapping {
  alpha : Double
  log_gamma : Double
}

///|
pub fn Mapping::new(alpha : Double) -> Result[Mapping, SketchError] {
  if !(alpha >= 0.0001 && alpha <= 0.5) {
    return Err(InvalidAccuracy)
  }
  Ok({ alpha, log_gamma: @math.ln_1p(2.0 * alpha / (1.0 - alpha)), })
}

///|
pub fn Mapping::accuracy(self : Mapping) -> Double {
  self.alpha
}

///|
pub fn Mapping::key(
  self : Mapping,
  magnitude : Double,
) -> Result[Int32, SketchError] {
  if !(magnitude >= 1.0e-150 && magnitude <= 1.0e150) {
    return Err(InvalidValue)
  }
  Ok(@math.ceil(@math.ln(magnitude) / self.log_gamma).to_int())
}

///|
fn Mapping::representative(self : Mapping, key : Int32) -> Double {
  @math.exp(key.to_double() * self.log_gamma) * (1.0 - self.alpha)
}
