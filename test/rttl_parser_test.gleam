import rttl_parser.{Dotted, F, Pitch, ThirtySecond, Tone}
import gleam_parser as p
import gleam/should

pub fn rttl_test() {
  p.run(rttl_parser.tone_parser(), "32.f2")
  |> should.equal(Ok(Tone(pitch: Pitch(F, 2), duration: Dotted(ThirtySecond))))
}
