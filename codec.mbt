///|
/// Encode a validated sketch. Int64 counts are encoded by the MoonBit core codec.
pub fn Sketch::to_json_string(self : Sketch) -> String {
  @json.to_json(self.snapshot()).stringify()
}

///|
/// Reject oversized/deep/duplicate-key JSON before validating snapshot invariants.
/// The default 1 MiB cap can be raised deliberately by the caller.
pub fn Sketch::from_json_string(
  text : String,
  max_chars~ : Int32 = 1048576,
) -> Result[Sketch, SketchError] {
  if max_chars < 0 || text.length() > max_chars {
    return Err(InvalidSnapshot)
  }
  let snapshot : Snapshot = @json.from_json(
    @json.parse(text, max_nesting_depth=16, reject_duplicate_keys=true),
  ) catch {
    _ => return Err(InvalidSnapshot)
  }
  Sketch::restore(snapshot)
}
