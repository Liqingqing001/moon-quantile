///|
test "JSON snapshot roundtrip and malformed input" {
  let s = Sketch::new().unwrap()
  s.add(-42.0, weight=9007199254740990L).unwrap()
  s.add(0.0).unwrap()
  let encoded = s.to_json_string()
  assert_eq(Sketch::from_json_string(encoded).unwrap().snapshot(), s.snapshot())
  assert_true(
    Sketch::from_json_string(encoded, max_chars=2) is Err(InvalidSnapshot),
  )
  assert_true(Sketch::from_json_string("{}") is Err(InvalidSnapshot))
  assert_true(
    Sketch::from_json_string("{\"version\":1,\"version\":1}")
    is Err(InvalidSnapshot),
  )
  assert_true(Sketch::from_json_string("not JSON") is Err(InvalidSnapshot))
}
