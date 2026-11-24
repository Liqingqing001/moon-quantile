///|
#derive(FromJson)
struct Request {
  values : Array[Double]
  quantiles : Array[Double]
  accuracy : Double
  capacity : Int32
}

///|
#derive(ToJson)
struct Report {
  count : Int64
  bins : Int32
  estimates : Array[Json]
  merged_estimates : Array[Json]
  restored_estimates : Array[Json]
}

///|
fn json_values(values : Array[Double?]) -> Array[Json] {
  values.map(fn(value) {
    match value {
      Some(x) => @json.to_json(x)
      None => @json.null
    }
  })
}

///|
fn fail() -> Unit {
  println("{\"error\":\"Invalid input or sketch operation failed\"}")
  @env.exit(2)
}

///|
#cfg(target="js")
fn argument_offset() -> Int32 {
  2
}

///|
#cfg(not(target="js"))
fn argument_offset() -> Int32 {
  1
}

///|
fn main {
  let args = @env.args()
  let offset = argument_offset()
  if args.length() != offset + 1 {
    fail()
    return
  }
  let request : Request = @json.from_json(
    @json.parse(args[offset], max_nesting_depth=8, reject_duplicate_keys=true),
  ) catch {
    _ => {
      fail()
      return
    }
  }
  let s = match
    @sketch.Sketch::new(accuracy=request.accuracy, capacity=request.capacity) {
    Ok(s) => s
    Err(_) => {
      fail()
      return
    }
  }
  let a = @sketch.Sketch::new(
    accuracy=request.accuracy,
    capacity=request.capacity,
  ).unwrap()
  let b = @sketch.Sketch::new(
    accuracy=request.accuracy,
    capacity=request.capacity,
  ).unwrap()
  for i, value in request.values {
    if s.add(value) is Err(_) {
      fail()
      return
    }
    let shard = if i % 2 == 0 { a } else { b }
    if shard.add(value) is Err(_) {
      fail()
      return
    }
  }
  if a.merge(b) is Err(_) {
    fail()
    return
  }
  let qs = request.quantiles[:]
  let estimates = match s.quantiles(qs) {
    Ok(v) => v
    Err(_) => {
      fail()
      return
    }
  }
  let restored = @sketch.Sketch::from_json_string(s.to_json_string()).unwrap()
  let report : Report = {
    count: s.count(),
    bins: s.bin_count(),
    estimates: json_values(estimates),
    merged_estimates: json_values(a.quantiles(qs).unwrap()),
    restored_estimates: json_values(restored.quantiles(qs).unwrap()),
  }
  println(@json.to_json(report).stringify())
}
