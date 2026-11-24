///|
test "snapshot roundtrip detaches storage" {
  let s = Sketch::new().unwrap()
  for x in [-3.0, 0.0, 1.0, 50.0] {
    s.add(x).unwrap()
  }
  let snap = s.snapshot()
  let copy = Sketch::restore(snap).unwrap()
  assert_eq(copy.snapshot(), snap)
  copy.add(400.0).unwrap()
  assert_eq(s.snapshot(), snap)
  snap.positive[0] = (0, 100L)
  assert_eq(s.count(), 4L)
  assert_eq(s.positive.get(0), Some(1L))
}

///|
test "restore rejects corrupt metadata bins and counts" {
  let s = Sketch::new().unwrap()
  s.add(1.0).unwrap()
  let snap = s.snapshot()
  assert_true(Sketch::restore({ ..snap, version: 2, }) is Err(InvalidSnapshot))
  assert_true(Sketch::restore({ ..snap, total: 2L, }) is Err(InvalidSnapshot))
  assert_true(
    Sketch::restore({ ..snap, positive: [(0, 1L), (0, 1L)], total: 2L, })
    is Err(InvalidSnapshot),
  )
  assert_true(
    Sketch::restore({ ..snap, positive: [(2147483647, 1L)], })
    is Err(InvalidSnapshot),
  )
  assert_true(
    Sketch::restore({ ..snap, positive: [(0, -1L)], }) is Err(InvalidSnapshot),
  )
  assert_true(Sketch::restore({ ..snap, zeros: -1L, }) is Err(InvalidSnapshot))
}
