///|
fn main {
  let east = @sketch.Sketch::new().unwrap()
  let west = @sketch.Sketch::new().unwrap()
  for latency in [12.0, 14.0, 15.0, 18.0, 120.0] {
    east.add(latency).unwrap()
  }
  for latency in [10.0, 13.0, 19.0, 32.0, 400.0] {
    west.add(latency).unwrap()
  }
  east.merge(west).unwrap()
  println("Merged request latency (ms), lower-rank quantiles:")
  for q in [0.5, 0.95, 0.99, 1.0] {
    let value = east.quantile(q).unwrap().unwrap()
    println("q=\{q}: \{value}")
  }
  println("samples=\{east.count()}, bins=\{east.bin_count()}")
  println(
    "With ten samples, lower-rank p99 selects the ninth value; q=1 selects the maximum.",
  )
}
