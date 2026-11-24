///|
/// A bounded sparse sketch. No I/O, clock, FFI, or silent bucket collapsing.
pub struct Sketch {
  mapping : Mapping
  capacity : Int32
  positive : @sorted_map.SortedMap[Int32, Int64]
  negative : @sorted_map.SortedMap[Int32, Int64]
  mut zeros : Int64
  mut total : Int64
}

///|
/// Accuracy [0.0001, 0.5], capacity counts nonempty signed bins, not samples.
pub fn Sketch::new(
  accuracy~ : Double = 0.01,
  capacity~ : Int32 = 4096,
) -> Result[Sketch, SketchError] {
  let mapping = match Mapping::new(accuracy) {
    Ok(m) => m
    Err(e) => return Err(e)
  }
  if capacity < 1 || capacity > 1000000 {
    return Err(InvalidCapacity)
  }
  Ok({
    mapping,
    capacity,
    positive: @sorted_map.SortedMap([]),
    negative: @sorted_map.SortedMap([]),
    zeros: 0L,
    total: 0L,
  })
}

///|
pub fn Sketch::count(self : Sketch) -> Int64 {
  self.total
}

///|
pub fn Sketch::bin_count(self : Sketch) -> Int32 {
  self.positive.length() + self.negative.length()
}

///|
/// Integers only; total capped at 2^53-1 for portable rank arithmetic.
/// Nonzero values outside [1e-150, 1e150] in magnitude are rejected.
/// Errors leave all state unchanged.
pub fn Sketch::add(
  self : Sketch,
  value : Double,
  weight~ : Int64 = 1L,
) -> Result[Unit, SketchError] {
  if weight <= 0L {
    return Err(InvalidWeight)
  }
  if weight > 9007199254740991L - self.total {
    return Err(CountOverflow)
  }
  if value == 0.0 {
    self.zeros = self.zeros + weight
    self.total = self.total + weight
    return Ok(())
  }
  let key = match self.mapping.key(value.abs()) {
    Ok(k) => k
    Err(e) => return Err(e)
  }
  let bins = if value < 0.0 { self.negative } else { self.positive }
  if !bins.contains(key) && self.bin_count() >= self.capacity {
    return Err(CapacityExceeded)
  }
  bins.set(key, bins.get_or_default(key, 0L) + weight)
  self.total = self.total + weight
  Ok(())
}
