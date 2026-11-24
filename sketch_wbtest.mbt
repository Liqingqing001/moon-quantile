///|
test "weighted signed ingestion and atomic capacity failure" {
  let s = Sketch::new(capacity=2).unwrap()
  s.add(-2.0, weight=3L).unwrap()
  s.add(5.0).unwrap()
  s.add(0.0, weight=2L).unwrap()
  assert_eq(s.count(), 6L)
  assert_eq(s.bin_count(), 2)
  assert_eq(s.add(100.0), Err(CapacityExceeded))
  assert_eq(s.count(), 6L)
  s.add(5.0).unwrap()
  assert_eq(s.count(), 7L)
}

///|
test "invalid samples and counter overflow are atomic" {
  let s = Sketch::new().unwrap()
  assert_eq(s.add(0.0 / 0.0), Err(InvalidValue))
  assert_eq(s.add(1.0 / 0.0), Err(InvalidValue))
  assert_eq(s.add(1.0, weight=0L), Err(InvalidWeight))
  assert_eq(s.add(1.0e-151), Err(InvalidValue))
  assert_eq(s.count(), 0L)
  s.add(1.0, weight=9007199254740991L).unwrap()
  assert_eq(s.add(0.0), Err(CountOverflow))
  assert_eq(s.count(), 9007199254740991L)
}
