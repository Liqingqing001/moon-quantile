///|
/// Versioned logical snapshot; not Datadog protobuf wire format.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct Snapshot {
  version : Int32
  accuracy : Double
  capacity : Int32
  positive : Array[(Int32, Int64)]
  negative : Array[(Int32, Int64)]
  zeros : Int64
  total : Int64
}

///|
/// Detached copies in ascending key order, suitable for deterministic encoding.
pub fn Sketch::snapshot(self : Sketch) -> Snapshot {
  {
    version: 1,
    accuracy: self.mapping.alpha,
    capacity: self.capacity,
    positive: self.positive.to_array(),
    negative: self.negative.to_array(),
    zeros: self.zeros,
    total: self.total,
  }
}

///|
/// Validate all counts, keys, ordering, version, and capacity before restoring.
pub fn Sketch::restore(snapshot : Snapshot) -> Result[Sketch, SketchError] {
  if snapshot.version != 1 ||
    snapshot.zeros < 0L ||
    snapshot.total < snapshot.zeros ||
    snapshot.total > 9007199254740991L {
    return Err(InvalidSnapshot)
  }
  let s = match
    Sketch::new(accuracy=snapshot.accuracy, capacity=snapshot.capacity) {
    Ok(s) => s
    Err(_) => return Err(InvalidSnapshot)
  }
  if snapshot.positive.length() > s.capacity ||
    snapshot.negative.length() > s.capacity - snapshot.positive.length() {
    return Err(InvalidSnapshot)
  }
  let min_key = s.mapping.key(1.0e-150).unwrap()
  let max_key = s.mapping.key(1.0e150).unwrap()
  let mut total = snapshot.zeros
  for bins in [snapshot.positive, snapshot.negative] {
    let mut previous = min_key - 1
    for (key, count) in bins {
      if key <= previous ||
        key < min_key ||
        key > max_key ||
        count <= 0L ||
        count > 9007199254740991L - total {
        return Err(InvalidSnapshot)
      }
      previous = key
      total = total + count
    }
  }
  if total != snapshot.total {
    return Err(InvalidSnapshot)
  }
  for (key, count) in snapshot.positive {
    s.positive.set(key, count)
  }
  for (key, count) in snapshot.negative {
    s.negative.set(key, count)
  }
  s.zeros = snapshot.zeros
  s.total = total
  Ok(s)
}
