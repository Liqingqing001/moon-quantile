///|
test "quantiles respect signed order zero and endpoint ranks" {
  let s = Sketch::new().unwrap()
  assert_eq(s.quantile(0.5), Ok(None))
  assert_eq(s.quantile(-0.1), Err(InvalidQuantile))
  for x in [-100.0, -2.0, 0.0, 5.0, 1000.0] {
    s.add(x).unwrap()
  }
  let expected = [-100.0, -2.0, 0.0, 5.0, 1000.0]
  for i = 0; i < 5; i = i + 1 {
    let actual = s.quantile(i.to_double() / 4.0).unwrap().unwrap()
    if expected[i] == 0.0 {
      assert_eq(actual, 0.0)
    } else {
      assert_true((actual / expected[i] - 1.0).abs() <= 0.01000000001)
    }
  }
  assert_eq(s.quantile(0.0 / 0.0), Err(InvalidQuantile))
}

///|
test "weights use lower rank without interpolation" {
  let s = Sketch::new().unwrap()
  s.add(1.0, weight=9L).unwrap()
  s.add(1000.0).unwrap()
  assert_true(s.quantile(0.99).unwrap().unwrap() < 2.0)
  assert_true(s.quantile(1.0).unwrap().unwrap() > 990.0)
  assert_eq(s.quantiles([0.0, 2.0]), Err(InvalidQuantile))
}
