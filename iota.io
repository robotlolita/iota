// # Module Iota
//
// A packrat parser combinator for Io.
//
//
// :licence: MIT
//   Copyright (c) 2013 Quildreen Motta <quildreen@gmail.com>
//
//   Permission is hereby granted, free of charge, to any person
//   obtaining a copy of this software and associated documentation files
//   (the "Software"), to deal in the Software without restriction,
//   including without limitation the rights to use, copy, modify, merge,
//   publish, distribute, sublicense, and/or sell copies of the Software,
//   and to permit persons to whom the Software is furnished to do so,
//   subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be
//   included in all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Iota := Object clone

// ## {} State<A>
//
// Represents the state of parsing an input.
Iota State := Object clone do(
  input  := ""
  index  := 0
  length := 0
  cache  := Map clone

  // ### with(input, index)
  //
  // Constructs a new state for the parser.
  //
  // :: @State<A> => [B], number -> State<B>
  with := method(newInput, newIndex,
    new := self clone
    new input  = newInput
    new index  = newIndex
    new length = newInput size - newIndex
    new
  )

  // ### asString()
  //
  // Returns a textual representation of the parser state.
  //
  // :: () -> string
  asString := method(
    "Iota State(#{slice(0)})" interpolate
  )

  // ### slice(from[, to])
  //
  // Returns part of the input.
  //
  // :: @State<A> => number, number -> [A]
  // :: @State<A> => number -> [A]
  slice := method(from, to,
    if(call argCount == 2,
      input exclusiveSlice(from + index, to + index)
    ,
      input inclusiveSlice(from + index)
    )
  )

  // ### consume(size)
  //
  // Consumes the given size, returns nil if it can't.
  //
  // :: @State<A> => number -> [A]
  consume := method(size,
    if(size > length,
      nil
    ,
      slice(0, size)
    )
  )

  // ### skip(count)
  //
  // Skips the amount of characters specified, returns a new state.
  //
  // :: @State<A> => number -> State<A>
  skip := method(count,
    self with(input, index + count)
  )

  // ### chain(f)
  //
  // Consumes the next thing in the input and feeds the value
  // and the new state into the block.
  //
  // :: @State<A> => (A, State<B> -> State<B>) -> State<B>
  chain := method(f,
    f call(self consume(1), self skip(1))
  )

  // ### position()
  //
  // Returns the position of the parser.
  //
  // :: @State<A> => () -> Position
  position := method(
    Iota Position with(input, index)
  )
)

// ## {} Position
//
// Represents the position of a parser on an input.
Iota Position := Object clone do(
  input := ""
  index := 0

  // ### with(input, index)
  //
  // Constructs a new Position.
  //
  // :: @Position => string, number -> Position
  with := method(input, index,
    new := self clone
    new input = input
    new index = index
    new
  )

  // ### asLines(start, end)
  //
  // Returns a list of lines from start to end.
  //
  // :: @Position => number, number -> Position
  asLines := method(start, end,
    input inclusiveSlice(start, end) \
          asMutable replaceSeq("\r\n", "\r") \
          split("\r", "\n")
  )

  // ### line()
  //
  // Returns the position's line number.
  //
  // :: @Position => () -> number
  line := method(
    asLines(0, index) size
  )

  // ### column()
  //
  // Returns the position's column number.
  //
  // :: @Position => () -> column
  column := method(
    asLines(0, index) last size
  )

  // ### context()
  //
  // Returns the context of the position.
  //
  // :: @Position => number -> [string]
  context := method(depth,
    lines := asLines(0, input size)
    start := 0 max(line - depth)
    end   := lines size min(line + depth)

    lines slice(start, end)
  )

  // ### asString()
  //
  // Returns a textual representation of the context.
  //
  // :: @Position => () -> string
  asString := method(
    if(input != "",
      lines := context(3)
      end   := line min(3)
      """
--- Iota at line #{line}, column #{column} ---
#{lines slice(0, end) join("\n")}
#{" " repeated(column - 1)}^
#{lines slice(end) join("\n")}
      """ interpolate
    ,
      ""
    )
  )
)

// ## {} Result<A>
//
// Represents the result of applying a parser to a state.
Iota Result := Object clone do(
  value := nil

  // ### isError
  //
  // True if the Result represents a failure.
  //
  // :: boolean
  isError := false

  // ### with(value)
  //
  // Puts something into the monad.
  //
  // :: @Result<A> => B -> Result<B>
  with := method(newValue,
    new := self clone
    new value = newValue
    new
  )

  // ### chain(f)
  //
  // Monadic bind.
  //
  // :: @Result<A> => (A -> Result<B>) -> Result<B>
  chain := method(f,
    f call(value)
  )

  // ### map(f)
  //
  // Transforms the value in the functor.
  //
  // :: @Result<A> => (A -> B) -> Result<B>
  map := method(f,
    with(f call(value))
  )
)

// ## Result<A> <| Error<A>
//
// Represents a failure in parsing something.
Iota Error := Iota Result clone do(
  // ### isError
  //
  // True if the Result represents a failure.
  //
  // :: boolean
  isError := true
)

// ## Exception
//
// Provides detailed information about the failure in parsing something.
Iota Exception := Object clone do(
  errorMessage := nil
  position     := nil

  // ### with(reason, position)
  //
  // Constructs a new exception.
  //
  // :: @Exception => string, Position -> Exception
  with := method(reason, state,
    new := self clone
    new errorMessage = reason
    new position     = state
    new
  )

  // ### asString()
  //
  // Provides a textual representation of the exception.
  //
  // :: @Exception => () -> string
  asString := method(
    "Parser Exception: #{errorMessage}\n#{position}" interpolate
  )
)

// ## {} Parser<A>
//
// The base parser object.
Iota Parser := Object clone do(
  state  := nil
  result := nil

  // ### with(state, result)
  //
  // Constructs a new parser for the given state/result pair
  //
  // :: @Parser<A> => State<B>, Result<C> -> Parser<B>
  with := method(state, result,
    new := self clone
    new state  = state
    new result = result
    new
  )

  // ### fail(message)
  //
  // Indicates general failure to parse something.
  //
  // :: @Parser<A> => string -> Parser<A>
  fail := method(errorMessage,
    ex := Iota Exception with(errorMessage, state position)
    with(state, Iota Error with(ex))
  )

  // ### match(value)
  //
  // Successfully matches the value.
  //
  // :: @Parser<A> => Result<B>, State<C> -> Parser<C>
  match := method(value, newState,
    with(newState, Iota Result with(value))
  )

  // ### either(consequent, alternate)
  //
  // Calls consequent if the parser is in a consistent state, alternate
  // if it's ain an error state.
  //
  // :: @Parser<A> => (A -> Parser<B>), (A -> Parser<C>) -> Parser<B> | Parser<C>
  either := method(consequent, alternate,
    if(result isError,
      alternate call(self)
    ,
      consequent call(self)
    )
  )

  // ### map(f)
  //
  // Transforms the value of the parser.
  //
  // :: @Parser<A> => (Result<B> -> Result<C>) -> Parser<A>
  map := method(f,
    with(state, f call(result))
  )

  // ### for(text)
  //
  // Yields a parser for the given input.
  //
  // :: @Parser<A> => B -> Parser<B>
  for := method(text,
    with(Iota State with(text, 0), nil)
  )

  // ### satisfy(f)
  //
  // Succeeds if the predicate holds for the next state input.
  //
  // :: @Parser<A> => (A, State<B> -> bool) -> Parser<B> | Parser<A>
  satisfy := method(f,
    newValue := nil
    newState := state chain(block(value, stateB,
                              if(f call(value),
                                newValue = match(value, stateB)
                                stateB
                              ,
                                newValue = fail("Failed to satisfy #{f message}")
                                state
                              )
                            ))
    newValue
  )

  // ### ?(message)
  //
  // Maps the error if the parser is in an error state.
  //
  // :: @Parser<A> => message -> Parser<A>
  ? := method(newMessage,
    either(
      block(map(block(a, a)))
    ,
      block(map(block(a, ex := Iota Exception with(newMessage, state position)
                         Iota Error with(ex))))
    )
  )
)

// ## {} Combinators
//
// Trait for combining parsers.
Iota Combinators := Object clone do(


)

// ## {} CharParser
//
// Trait for parsing character-based input.
Iota CharParser := Object clone do(
  // ### char(x)
  //
  // Succeeds if the input matches the character.
  //
  // :: @Parser<A> => B -> Parser<B> | Parser<A>
  char := method(character,
    satisfy(block(actual, actual == character)) \
    ? "Expected \"#{character}\"" interpolate
  )

  // ### oneOf(xs)
  //
  // Succeeds if the input match any of the characters.
  //
  // :: @Parser<A> => B -> Parser<B> | Parser<A>
  oneOf := method(characters,
    satisfy(block(actual, characters containsSeq(actual))) \
    ? "Expected one of \"#{characters}\"" interpolate
  )

  // ### noneOf(xs)
  //
  // Succeeds if the input match none of the characters.
  //
  // :: @Parser<A> => B -> Parser<B> | Parser<A>
  noneOf := method(characters,
    satisfy(block(actual, characters containsSeq(actual) not)) \
    ? "Expected none of \"#{characters}\"" interpolate
  )

  // ### string(xs)
  //
  // Succeeds if the input matches the sequence of characters.
  //
  // :: @Parser<A> => B -> Parser<B> | Parser<A>
  string := method(text,
    actual := state consume(text size)
    if(actual == text,
      match(actual, state skip(text size))
    ,
      fail("Expected \"#{text}\"" interpolate)
    )
  )
)

Iota setProtos(list(
  Iota Parser,
  Iota CharParser
))