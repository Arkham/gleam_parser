import gleam/pair
import gleam/string
import gleam/list.{Continue, Stop}
import gleam/int
import gleam/float

pub type State {
  State(input: List(String), row: Int, col: Int)
}

pub type Parser(a) {
  Parser(fn(State) -> tuple(State, Result(a, List(DeadEnd))))
}

pub type DeadEnd {
  DeadEnd(row: Int, col: Int, problem: Problem)
}

pub type Problem {
  ExpectingSymbol(symbol: String)
  ExpectingInt
}

fn to_dead_end(state: State, problem: Problem) -> DeadEnd {
  DeadEnd(row: state.row, col: state.col, problem: problem)
}

pub fn run(parser: Parser(a), input: String) -> Result(a, List(DeadEnd)) {
  let Parser(parse) = parser
  let input_graphemes = string.to_graphemes(input)

  State(input: input_graphemes, row: 1, col: 1)
  |> parse()
  |> pair.second()
}

pub fn symbol(needle: String) -> Parser(Nil) {
  let needle_length = string.length(needle)
  let needle_graphemes = string.to_graphemes(needle)

  Parser(fn(state: State) {
    case list.take(state.input, needle_length) == needle_graphemes {
      True -> tuple(
        State(
          ..state,
          input: list.drop(state.input, needle_length),
          col: state.col + needle_length,
        ),
        Ok(Nil),
      )
      _ -> tuple(state, Error([to_dead_end(state, ExpectingSymbol(needle))]))
    }
  })
}

pub fn int() -> Parser(Int) {
  Parser(fn(state: State) {
    let digits =
      state.input
      |> list.fold_until(
        [],
        fn(el, acc) {
          case el {
            "0" -> Continue([0, ..acc])
            "1" -> Continue([1, ..acc])
            "2" -> Continue([2, ..acc])
            "3" -> Continue([3, ..acc])
            "4" -> Continue([4, ..acc])
            "5" -> Continue([5, ..acc])
            "6" -> Continue([6, ..acc])
            "7" -> Continue([7, ..acc])
            "8" -> Continue([8, ..acc])
            "9" -> Continue([9, ..acc])
            "." -> Stop([])
            _ -> Stop(acc)
          }
        },
      )
    case digits {
      [] -> tuple(state, Error([to_dead_end(state, ExpectingInt)]))
      _ -> {
        let rest = list.drop(state.input, list.length(digits))
        let return_value =
          digits
          |> list.index_fold(
            0,
            fn(index, item, acc) {
              let factor = float.round(float.power(10.0, int.to_float(index)))
              item * factor + acc
            },
          )
        tuple(
          State(..state, input: rest, col: state.col + list.length(digits)),
          Ok(return_value),
        )
      }
    }
  })
}

// combinator building blocks
pub fn succeed(value: a) -> Parser(a) {
  Parser(fn(state) { tuple(state, Ok(value)) })
}

pub fn keep(mapper: Parser(fn(a) -> b), first: Parser(a)) -> Parser(b) {
  map2(mapper, first, fn(a, b) { a(b) })
}

pub fn leave(keep: Parser(a), leave: Parser(b)) -> Parser(a) {
  map2(keep, leave, fn(a, _) { a })
}

// map over a parser
pub fn map(parser: Parser(a), map_fun: fn(a) -> b) -> Parser(b) {
  let Parser(parse) = parser

  Parser(fn(state: State) {
    let result = parse(state)
    case result.1 {
      Ok(value) -> tuple(result.0, Ok(map_fun(value)))
      Error(errs) -> tuple(state, Error(errs))
    }
  })
}

// chain two parsers together
pub fn map2(
  a_parser: Parser(a),
  b_parser: Parser(b),
  map_fun: fn(a, b) -> value,
) -> Parser(value) {
  let Parser(parse_a) = a_parser
  let Parser(parse_b) = b_parser

  Parser(fn(state: State) {
    let parse_a_result = parse_a(state)
    case parse_a_result.1 {
      Ok(a_value) -> {
        let parse_b_result = parse_b(parse_a_result.0)
        case parse_b_result.1 {
          Ok(b_value) -> tuple(parse_b_result.0, Ok(map_fun(a_value, b_value)))
          Error(errs) -> tuple(state, Error(errs))
        }
      }

      Error(errs) -> tuple(state, Error(errs))
    }
  })
}
