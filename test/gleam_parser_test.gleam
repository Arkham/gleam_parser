import gleam_parser.{ExpectingInt, ExpectingSymbol} as p
import gleam/should
import gleam/int

// SYMBOLS
pub fn symbol_success_test() {
  p.run(p.symbol(","), ",")
  |> should.equal(Ok(Nil))
}

pub fn symbol_multi_character_success_test() {
  p.run(p.symbol("foo"), "foobar")
  |> should.equal(Ok(Nil))
}

pub fn symbol_failure_test() {
  p.run(p.symbol(","), ":")
  |> should.equal(Error([p.DeadEnd(1, 1, ExpectingSymbol(","))]))
}

pub fn symbol_empty_string_test() {
  p.run(p.symbol(","), "")
  |> should.equal(Error([p.DeadEnd(1, 1, ExpectingSymbol(","))]))
}

pub fn symbol_deadend_tracks_context_test() {
  let parser =
    p.symbol("foo")
    |> p.leave(p.symbol("bar"))

  p.run(parser, "foobar")
  |> should.equal(Ok(Nil))

  p.run(parser, "foospam")
  |> should.equal(Error([p.DeadEnd(1, 4, ExpectingSymbol("bar"))]))
}

// INTS
pub fn int_success_test() {
  p.run(p.int(), "100")
  |> should.equal(Ok(100))
}

pub fn int_failure_test() {
  p.run(p.int(), "bar")
  |> should.equal(Error([p.DeadEnd(1, 1, ExpectingInt)]))
}

pub fn int_followed_by_period_failure_test() {
  p.run(p.int(), "100.")
  |> should.equal(Error([p.DeadEnd(1, 1, ExpectingInt)]))
}

pub fn int_deadend_tracks_context_test() {
  let parser =
    p.int()
    |> p.leave(p.symbol("bar"))

  p.run(parser, "100bar")
  |> should.equal(Ok(100))

  p.run(parser, "100spam")
  |> should.equal(Error([p.DeadEnd(1, 4, ExpectingSymbol("bar"))]))
}

// COMBINATORS
type IntResult {
  IntResult(int: Int)
}

pub fn discard_symbol_but_keep_int_test() {
  let parser =
    p.succeed(IntResult)
    |> p.leave(p.symbol("hi"))
    |> p.keep(p.int())

  p.run(parser, "hi500")
  |> should.equal(Ok(IntResult(500)))
}

type FloatResult {
  FloatResult(float: Float)
}

pub fn map_over_parsing_success_test() {
  let parser =
    p.succeed(FloatResult)
    |> p.keep(
      p.int()
      |> p.map(int.to_float),
    )

  p.run(parser, "100")
  |> should.equal(Ok(FloatResult(100.0)))

  p.run(parser, "foo")
  |> should.equal(Error([p.DeadEnd(1, 1, ExpectingInt)]))
}
