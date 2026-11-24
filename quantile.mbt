///|
/// Lower order statistic at floor(q*(count-1)), without interpolation.
/// Empty sketches return Ok(None); invalid q returns Err even when empty.
pub fn Sketch::quantile(
  self : Sketch,
  q : Double,
) -> Result[Double?, SketchError] {
  if !(q >= 0.0 && q <= 1.0) {
    return Err(InvalidQuantile)
  }
  if self.total == 0L {
    return Ok(None)
  }
  let rank = @math.floor(q * (self.total - 1L).to_double()).to_int64()
  let mut seen = 0L
  for key, count in self.negative.rev_iter2() {
    seen = seen + count
    if seen > rank {
      return Ok(Some(-self.mapping.representative(key)))
    }
  }
  seen = seen + self.zeros
  if seen > rank {
    return Ok(Some(0.0))
  }
  for key, count in self.positive.iter2() {
    seen = seen + count
    if seen > rank {
      return Ok(Some(self.mapping.representative(key)))
    }
  }
  // Construction and mutation preserve the count invariant.
  Err(InvalidSnapshot)
}

///|
/// Query several quantiles. Reject invalid probabilities before producing output.
pub fn Sketch::quantiles(
  self : Sketch,
  qs : ArrayView[Double],
) -> Result[Array[Double?], SketchError] {
  let out = []
  for q in qs {
    match self.quantile(q) {
      Ok(value) => out.push(value)
      Err(e) => return Err(e)
    }
  }
  Ok(out)
}
