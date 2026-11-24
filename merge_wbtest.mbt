///|
test "merge equals single stream and does not mutate source" {
  let whole = Sketch::new().unwrap()
  let a = Sketch::new().unwrap()
  let b = Sketch::new().unwrap()
  for i = -200; i < 201; i = i + 1 {
    whole.add(i.to_double()).unwrap()
    if i % 2 == 0 {
      a.add(i.to_double()).unwrap()
    } else {
      b.add(i.to_double()).unwrap()
    }
  }
  a.merge(b).unwrap()
  assert_eq(a.count(), whole.count())
  assert_eq(b.count(), 200L)
  assert_eq(
    a.quantiles([0.0, 0.01, 0.5, 0.99, 1.0]),
    whole.quantiles([0.0, 0.01, 0.5, 0.99, 1.0]),
  )
  a.merge(a).unwrap()
  assert_eq(a.count(), 802L)
}

///|
test "failed merge preserves bins and count" {
  let a = Sketch::new(capacity=1).unwrap()
  let b = Sketch::new().unwrap()
  a.add(1.0).unwrap()
  b.add(100.0).unwrap()
  assert_eq(a.merge(b), Err(CapacityExceeded))
  assert_eq(a.count(), 1L)
  assert_eq(a.bin_count(), 1)
  assert_eq(
    a.merge(Sketch::new(accuracy=0.1).unwrap()),
    Err(IncompatibleConfig),
  )
  let large = Sketch::new().unwrap()
  large.add(0.0, weight=9007199254740991L).unwrap()
  assert_eq(a.merge(large), Err(CountOverflow))
  assert_eq(a.count(), 1L)
}
