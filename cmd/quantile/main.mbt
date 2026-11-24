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
  estimates : Array[Double?]
  merged_estimates : Array[Double?]
  restored_estimates : Array[Double?]
}

///|
fn fail() -> Unit {
  println("{\"error\":\"Invalid input or sketch operation failed\"}")
  @env.exit(2)
}

///|
fn main {
  let args = @env.args()
  if args.length() != 2 {
    fail()
    return
  }
  let request : Request = @json.from_json(
    @json.parse(args[1], max_nesting_depth=8, reject_duplicate_keys=true),
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
    estimates,
    merged_estimates: a.quantiles(qs).unwrap(),
    restored_estimates: restored.quantiles(qs).unwrap(),
  }
  println(@json.to_json(report).stringify())
}
