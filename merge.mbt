///|
/// Merge a compatible sketch. Capacity and overflow are preflighted before mutation.
/// Capacity may differ; accuracy must match exactly. Self-merge doubles counts.
pub fn Sketch::merge(
  self : Sketch,
  other : Sketch,
) -> Result[Unit, SketchError] {
  if self.mapping.alpha != other.mapping.alpha {
    return Err(IncompatibleConfig)
  }
  if other.total > 9007199254740991L - self.total {
    return Err(CountOverflow)
  }
  let mut required = self.bin_count()
  for key in other.positive.keys() {
    if !self.positive.contains(key) {
      required = required + 1
    }
  }
  for key in other.negative.keys() {
    if !self.negative.contains(key) {
      required = required + 1
    }
  }
  if required > self.capacity {
    return Err(CapacityExceeded)
  }
  // Copy the source bin arrays so aliasing/self-merge is well defined.
  let positive = other.positive.to_array()
  let negative = other.negative.to_array()
  let zeros = other.zeros
  let total = other.total
  for (key, count) in positive {
    self.positive.set(key, self.positive.get_or_default(key, 0L) + count)
  }
  for (key, count) in negative {
    self.negative.set(key, self.negative.get_or_default(key, 0L) + count)
  }
  self.zeros = self.zeros + zeros
  self.total = self.total + total
  Ok(())
}
