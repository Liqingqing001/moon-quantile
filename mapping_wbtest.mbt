///|
test "mapping rejects nonfinite accuracy and out of range magnitudes" {
  assert_true(Mapping::new(0.0) is Err(InvalidAccuracy))
  assert_true(Mapping::new(0.0 / 0.0) is Err(InvalidAccuracy))
  let m = Mapping::new(0.01).unwrap()
  assert_true(m.key(0.0) is Err(InvalidValue))
  assert_true(m.key(1.0e151) is Err(InvalidValue))
  assert_true(m.key(-1.0) is Err(InvalidValue))
}

///|
test "logarithmic mapping error across thirty decades" {
  for alpha in [0.0001, 0.01, 0.1, 0.5] {
    let m = Mapping::new(alpha).unwrap()
    for i = -15000; i <= 15000; i = i + 37 {
      let value = @math.exp(i.to_double() / 100.0)
      let k = m.key(value).unwrap()
      assert_true((m.representative(k) / value - 1.0).abs() <= alpha + 1.0e-12)
    }
  }
}
