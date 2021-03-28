import gleam_parser.{Parser} as p
import gleam/function

pub type Note {
  A
  Bb
  B
  C
  Db
  D
  Eb
  E
  F
  Gb
  G
  Ab
}

pub type Pitch {
  Pitch(note: Note, octave: Int)
}

pub type DurationLength {
  Whole
  Half
  Quarter
  Eighth
  Sixteenth
  ThirtySecond
}

pub type Duration {
  Normal(length: DurationLength)
  Dotted(length: DurationLength)
}

pub type Tone {
  Tone(duration: Duration, pitch: Pitch)
  Pause(duration: Duration)
}

pub fn with_sharp(note: String, current: Note, sharped: Note) -> Parser(Note) {
  p.one_of([
    p.succeed(sharped)
    |> p.leave(p.symbol("#"))
    |> p.leave(p.symbol(note)),
    p.succeed(current)
    |> p.leave(p.symbol(note)),
  ])
}

pub fn note_parser() -> Parser(Note) {
  p.one_of([
    with_sharp("a", A, Bb),
    with_sharp("b", B, C),
    with_sharp("c", C, Db),
    with_sharp("d", D, Eb),
    with_sharp("e", E, F),
    with_sharp("f", F, Gb),
    with_sharp("g", G, Ab),
  ])
}

pub fn octave_parser() -> Parser(Int) {
  p.one_of([
    p.succeed(1)
    |> p.leave(p.symbol("1")),
    p.succeed(2)
    |> p.leave(p.symbol("2")),
    p.succeed(3)
    |> p.leave(p.symbol("3")),
  ])
}

pub fn pitch_parser() -> Parser(Pitch) {
  p.succeed(function.curry2(Pitch))
  |> p.keep(note_parser())
  |> p.keep(octave_parser())
}

pub fn duration_lenth_parser() -> Parser(DurationLength) {
  p.one_of([
    p.succeed(ThirtySecond)
    |> p.leave(p.symbol("32")),
    p.succeed(Sixteenth)
    |> p.leave(p.symbol("16")),
    p.succeed(Sixteenth)
    |> p.leave(p.symbol("16")),
    p.succeed(Eighth)
    |> p.leave(p.symbol("8")),
    p.succeed(Quarter)
    |> p.leave(p.symbol("4")),
    p.succeed(Half)
    |> p.leave(p.symbol("2")),
    p.succeed(Whole)
    |> p.leave(p.symbol("1")),
  ])
}

pub fn duration_parser() -> Parser(Duration) {
  p.one_of([
    p.succeed(Dotted)
    |> p.keep(duration_lenth_parser())
    |> p.leave(p.symbol(".")),
    p.succeed(Normal)
    |> p.keep(duration_lenth_parser()),
  ])
}

pub fn tone_parser() -> Parser(Tone) {
  p.one_of([
    p.succeed(function.curry2(Tone))
    |> p.keep(duration_parser())
    |> p.keep(pitch_parser()),
    p.succeed(Pause)
    |> p.keep(duration_parser())
    |> p.leave(p.symbol("-")),
  ])
}
