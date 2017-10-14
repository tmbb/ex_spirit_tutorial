# First Parsers

## Introduction to the Context

In the previous chapter you've defined a parsing module:

$$ include "lib/ex_spirit_tutorial/setup/example_text_parser.ex"

ExSpirit has injected some functions and macros into that module that you can play with.
Let's open up an `iex` session and import that module.

```elixir
iex> import ExSpiritTutorial.Setup.ExampleTextParser
ExSpiritTutorial.Setup.ExampeTextParser
```

Let's parse a character:

```elixir
iex> parse("a", char())
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 97, rulestack: [], skipper: nil, state: %{},
 userdata: nil}
```

What is this? We've tried to parse a character out of a string, and instead of a sensible result, like a character, or a list of characters or something like that, we get a monster `struct` with lots of fields!

Let's try to decompose the `struct` in a way that makes sense:

```elixir
iex> context = parse("a", char())
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 97, rulestack: [], skipper: nil, state: %{},
 userdata: nil}
iex> context.result
97
iex> ?a
97
```

So, the `struct` contains a `result`, which is what we expect: we've parse the character `?a` (remember that Elixir makes no distinction between characters and numbers).
Let's explore it further. The `filename`, `line`, `column` and `position` are pretty obvious:

```elixir
iex> context.filename
"<unknown>"
iex> {context.line, context.column}
{1, 2}
iex> context.position
1
```

The represent the position of the parser along the string:

  * The `filename` is `"<unknown>"`, because we are parsing from a string and not from a file
  * The `line` and `column` fields represent the current line and column, and per the usual convention ExSpirit starts counting line and column numbers at 1 instead of 0
  * The `position` field represents the position along the sting *in bytes* (not characters!)

These fields are very useful for error reporting.
Besides that, we can tag the tokens we parse with position information, which can be useful for debugging later.

```elixir
iex> context.error
nil
```

There is a field called `error`, which is currently `nil`.
This means that the parser has succeeded.
The absence of error means the presence of success.
We will explore different kinds of errors later.

We will ignore the fields `rulestack`, `skipper`, `state` and `userdata` for now.
We will go back to them later, of course, as some of these fields are essential to parse context-sensitive grammars

We still haven't discussed the `rest` field.
The `rest` field is merely the bytes we still haven't consumed.
Let's see what `iex` tells us:

```elixir
iex> context.rest
""
```

This means we've consume the whole string and there is nothing left.
This is expected, as we've tried to parse a single character out of a string with a single character.

Let's try another example:

```elixir
iex> %{result: result, rest: rest} = parse("ab", char())
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "b", result: 97, rulestack: [], skipper: nil, state: %{},
 userdata: nil}
iex> {result, rest}
{97, "b"}
iex> ?a
97
```

Now we've tried to parse a single character out of a string with two characters.
We can see that the `result` is the same as above, but now the `rest` is different.
There is still a binary with one byte left (i.e. `"b"`).

This "monster `struct`" is the Context.
While consuming bytes from the stream, ExSpirit will thread the Context along, updating it as bytes are consumed.

The primitive parsers abstract away the context, so that you only see it in the final result value.
In the intermediate steps it looks as if you're just defining declarative grammar rules that operate on a simple string.
This allows for simpler parser definitions for PEG parsers.

On the other hand, the real power of ExSpirit lies in the ability to have the context available at any moment, so that you can:

  * annotate tokens with context data (like position information)
  * pass constant parameters to a rule deep into the grammar
  * or even feed data from the context to the next parser so that it can use that information on what to do next.

This allows you to create context-dependent combinators, which you can use to parse context-sensitive languages.

### Unicode and Other Encodings

If you're paying attention, you've probably noticed how we've talked about characters and bytes in different contexts.
If you're interested in parsing files encoded with UTF-8 that may contain characters outside the ASCII range, this is an important distinction.
ExSpirit uses UTF-8 underneath for all character-related functionality, which means it handles Unicode just fine.
For example, let's try to parse a character out of this string:

```elixir
iex> %{result: result, rest: rest, position: position} = parse("Átomo", char())
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 2, rest: "tomo", result: 193, rulestack: [], skipper: nil,
 state: %{}, userdata: nil}
iex> {result, rest, position}
{193, "tomo", 2}
iex> ?Á
193
iex> byte_size("Á")
2
```

You can see that ExSpirit has correctly parsed the single character `?Á`, even though it's not an ASCII character.
Although a single character was parsed, two bytes were consumed, and that's why `position` is two.

Although ExSpirit handles UTF-8 by default, this doesn't mean that ExSpirit is restricted to parsing UTF-8.
You can write your own primitive parsers that accept a certain encoding and use ExSpirit's combinator parsers on top of those primiive parsers.

## From a PEG Grammar to an ExSpirit Grammar

A PEG grammar supports the following operations:

  * Sequence: `e1 e2` - parser `e1` after parser `e2`
  * Ordered choice: `e1 / e2` - parser `e1` or parser `e2`, the fist that matches
  * Zero-or-more: `e*` - parser `e`, repeated zero or more times
  * One-or-more: `e+` - parser `e`, repeated one or more times
  * Optional: `e?` - parser `e` or nothing
  * And-predicate: `&e`, also called positive lookahead: test if parser `e` matches the rest of the input, but doesn't consume input itself. Succeeds if it matches the input.
  * Not-predicate: `!e`, also called negative lookahead: test if parser `e` matches the rest of the input, and succeeds it it fails to match.

Now let's see how we can emulate a PEG grammar with ExSpirit.
Let's define a parser module with some parsers:

$$ include "lib/ex_spirit_tutorial/peg_parsers/peg_operations.ex"

Now, fire up `iex` and import the module to play with it a little:

```elixir
iex> import ExSpiritTutorial.PegParsers.PegOperations
ExSpiritTutorial.PegParsers.PegOperations
```

### Sequence - `seq`

In a PEG grammar, sequence is denoted by juxtaposition of parsers: `e1 e2`.
Instead of using this syntax, ExSpirit defines the [`ExSpirit.Parser.seq/2`] combinator:

```elixir
iex> %{error: nil} = parse("xy", seq([e1, e2]))
%ExSpirit.Parser.Context{column: 3, error: nil, filename: "<unknown>", line: 1,
 position: 2, rest: "", result: 'xy', rulestack: [], skipper: nil, state: %{},
 userdata: nil}
```

If you try to parse an invalid sequence, it will fail with an error.

```elixir
iex> %{error: error} = parse("xa", seq([e1, e2]))
%ExSpirit.Parser.Context{column: 2,
 error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 2,
   error: nil, filename: "<unknown>", line: 1, position: 1, rest: "a",
   result: 120, rulestack: [:e2], skipper: nil, state: %{}, userdata: nil},
  extradata: nil,
  message: "Tried parsing out any of the the characters of `'y'` but failed due to the input character not matching"},
 filename: "<unknown>", line: 1, position: 1, rest: "a", result: 120,
 rulestack: [], skipper: nil, state: %{}, userdata: nil}
```

In fact, the error is quite descriptive:

```elixir
iex> error
%ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 2,
  error: nil, filename: "<unknown>", line: 1, position: 1, rest: "a",
  result: 120, rulestack: [:e2], skipper: nil, state: %{}, userdata: nil},
 extradata: nil,
 message: "Tried parsing out any of the the characters of `'y'` but failed due to the input character not matching"}
```

It tells you dat at that context (`position: 1`, that is, after consuming a single byte), it was expecting to find one of the characters in `[?y]`.

You can see that `seq([e1, e2])` is equivalent to `e1 e2` in PEG notation.

### Ordered Choice - `alt`

In a PEG grammar, sequence is denoted by the `/` operator: `e1 / e2`.
Instead of using this syntax, ExSpirit defines the [`ExSpirit.Parser.alt/2`] combinator:

```elixir
iex> %{error: nil} = parse("x", alt([e1, e2]))
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 120, rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("y", alt([e1, e2]))
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 121, rulestack: [], skipper: nil, state: %{},
 userdata: nil}
```

It will fail when given an invalid character, of course:

```elixir
iex> %{error: error} = parse("b", alt([e1, e2]))
%ExSpirit.Parser.Context{column: 1,
 error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
   error: nil, filename: "<unknown>", line: 1, position: 0, rest: "b",
   result: nil, rulestack: [:e2], skipper: nil, state: %{}, userdata: nil},
  extradata: nil,
  message: "Tried parsing out any of the the characters of `'y'` but failed due to the input character not matching"},
 filename: "<unknown>", line: 1, position: 0, rest: "b", result: nil,
 rulestack: [], skipper: nil, state: %{}, userdata: nil}

iex> error
%ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
  error: nil, filename: "<unknown>", line: 1, position: 0, rest: "b",
  result: nil, rulestack: [:e2], skipper: nil, state: %{}, userdata: nil},
 extradata: nil,
 message: "Tried parsing out any of the the characters of `'y'` but failed due to the input character not matching"}
iex(13)>
```

Look at the error message above.
It's telling us that the parser failed to parse the `?y` character. Why?
Remember that PEG parsers try to match the alternatives in order.
When the first alternative  (`?x`) fails, there is no problem, as there are still other alternatives to test.
But when the second alternative  (`?y`) fails, there are no more alternatives, and the parser fails with the error.

You can see that `alt([e1, e2])` is equivalent to `e1 / e2` in PEG notation.

### Zero Or More - `repeat/2`

In a PEG grammar, sequence is denoted by the `*` postfix operator: `e*`.
Instead of using this syntax, ExSpirit defines the [`ExSpirit.Parser.repeat/2`] combinator:

```elixir
iex> %{error: nil} = parse("", repeat(e))
%ExSpirit.Parser.Context{column: 1, error: nil, filename: "<unknown>", line: 1,
 position: 0, rest: "", result: [], rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("a", repeat(e))
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 'a', rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("aa", repeat(e))
%ExSpirit.Parser.Context{column: 3, error: nil, filename: "<unknown>", line: 1,
 position: 2, rest: "", result: 'aa', rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("aaaa", repeat(e))
%ExSpirit.Parser.Context{column: 5, error: nil, filename: "<unknown>", line: 1,
 position: 4, rest: "", result: 'aaaa', rulestack: [], skipper: nil, state: %{},
 userdata: nil}
```

The `repeat` combinator will apply the parser given as argument as many times as possible and gather the results into a list.
As you can see, the result is always a list of the `?a` character, repeated on or more times.

### One Or More - `repeat/3` again

There is no specific combinator to match one or more repetitions of a given parser, but
you can pass a minimal number of repetitions to the `repeat` combinator.
If you pass a minimum of 1 repetition, you can emulate the "One Or More" operation.

```elixir
iex> %{error: error} = parse("", repeat(e, 1))
%ExSpirit.Parser.Context{column: 1,
 error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
   error: nil, filename: "<unknown>", line: 1, position: 0, rest: "",
   result: nil, rulestack: [], skipper: nil, state: %{}, userdata: nil},
  extradata: 0,
  message: "Repeating over a parser failed due to not reaching the minimum amount of 1 with only a repeat count of 0"},
 filename: "<unknown>", line: 1, position: 0, rest: "", result: nil,
 rulestack: [], skipper: nil, state: %{}, userdata: nil}

iex(23)> %{error: nil} = parse("a", repeat(e, 1))
%ExSpirit.Parser.Context{column: 2, error: nil, filename: "<unknown>", line: 1,
 position: 1, rest: "", result: 'a', rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("aa", repeat(e, 1))
%ExSpirit.Parser.Context{column: 3, error: nil, filename: "<unknown>", line: 1,
 position: 2, rest: "", result: 'aa', rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> %{error: nil} = parse("aaaa", repeat(e, 1))
%ExSpirit.Parser.Context{column: 5, error: nil, filename: "<unknown>", line: 1,
 position: 4, rest: "", result: 'aaaa', rulestack: [], skipper: nil, state: %{},
 userdata: nil}
```

### Optional

TODO: What's the best equivalent to optional?

### And-Predicate - `lookahead`

```elixir
iex> %{error: nil, result: result, rest: rest} = parse("a", lookahead(e))
%ExSpirit.Parser.Context{column: 1, error: nil, filename: "<unknown>", line: 1,
 position: 0, rest: "a", result: nil, rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> {result, rest}
{nil, "a"}

iex> parse("x", lookahead(e))
%ExSpirit.Parser.Context{column: 1,
 error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
   error: nil, filename: "<unknown>", line: 1, position: 0, rest: "x",
   result: nil, rulestack: [], skipper: nil, state: %{}, userdata: nil},
  extradata: %ExSpirit.Parser.Context{column: 1,
   error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
     error: nil, filename: "<unknown>", line: 1, position: 0, rest: "x",
     result: nil, rulestack: [:e], skipper: nil, state: %{}, userdata: nil},
    extradata: nil,
    message: "Tried parsing out any of the the characters of `'a'` but failed due to the input character not matching"},
   filename: "<unknown>", line: 1, position: 0, rest: "x", result: nil,
   rulestack: [], skipper: nil, state: %{}, userdata: nil},
  message: "Lookahead failed"}, filename: "<unknown>", line: 1, position: 0,
 rest: "x", result: nil, rulestack: [], skipper: nil, state: %{}, userdata: nil}
```

### Not-Predicate - `lookahead_not`

```elixir
iex> parse("x", lookahead_not(e))
%ExSpirit.Parser.Context{column: 1, error: nil, filename: "<unknown>", line: 1,
 position: 0, rest: "x", result: nil, rulestack: [], skipper: nil, state: %{},
 userdata: nil}

iex> parse("a", lookahead_not(e))
%ExSpirit.Parser.Context{column: 1,
 error: %ExSpirit.Parser.ParseException{context: %ExSpirit.Parser.Context{column: 1,
   error: nil, filename: "<unknown>", line: 1, position: 0, rest: "a",
   result: nil, rulestack: [], skipper: nil, state: %{}, userdata: nil},
  extradata: %ExSpirit.Parser.Context{column: 2, error: nil,
   filename: "<unknown>", line: 1, position: 1, rest: "", result: 97,
   rulestack: [], skipper: nil, state: %{}, userdata: nil},
  message: "Lookahead_not failed"}, filename: "<unknown>", line: 1, position: 0,
 rest: "a", result: nil, rulestack: [], skipper: nil, state: %{}, userdata: nil}
```

## Parser Composition *vs* `seq`

## Examples

### Example - A Calculator

### Example - Parsing a String

### Example - A Parser for PEG Grammars


[`ExSpirit.Parser.Text.__using__/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.Text.html#__using__/1
[`ExSpirit.Parser.__using__/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#__using__/1
[`ExSpirit.Parser.alt/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#alt/2
[`ExSpirit.Parser.branch/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#branch/3
[`ExSpirit.Parser.defrule/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#defrule/1
[`ExSpirit.Parser.defrule/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#defrule/2
[`ExSpirit.Parser.eoi/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#eoi/1
[`ExSpirit.Parser.eoi/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#eoi/2
[`ExSpirit.Parser.expect/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#expect/2
[`ExSpirit.Parser.fail/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#fail/1
[`ExSpirit.Parser.fail/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#fail/2
[`ExSpirit.Parser.get_state_into/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#get_state_into/3
[`ExSpirit.Parser.ignore/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#ignore/2
[`ExSpirit.Parser.ignore/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#ignore/3
[`ExSpirit.Parser.lexeme/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#lexeme/2
[`ExSpirit.Parser.lookahead/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#lookahead/2
[`ExSpirit.Parser.lookahead_not/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#lookahead_not/2
[`ExSpirit.Parser.no_skip/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#no_skip/2
[`ExSpirit.Parser.parse/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#parse/2
[`ExSpirit.Parser.parse/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#parse/3
[`ExSpirit.Parser.pipe_context_around/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#pipe_context_around/3
[`ExSpirit.Parser.pipe_context_into/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#pipe_context_into/2
[`ExSpirit.Parser.pipe_result_into/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#pipe_result_into/2
[`ExSpirit.Parser.push_state/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#push_state/3
[`ExSpirit.Parser.put_state/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#put_state/3
[`ExSpirit.Parser.repeat/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeat/2
[`ExSpirit.Parser.repeat/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeat/3
[`ExSpirit.Parser.repeat/4`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeat/4
[`ExSpirit.Parser.repeatFn/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeatFn/2
[`ExSpirit.Parser.repeatFn/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeatFn/3
[`ExSpirit.Parser.repeatFn/4`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#repeatFn/4
[`ExSpirit.Parser.seq/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#seq/2
[`ExSpirit.Parser.skip/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#skip/1
[`ExSpirit.Parser.skipper/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#skipper/3
[`ExSpirit.Parser.success/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#success/1
[`ExSpirit.Parser.success/2`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#success/2
[`ExSpirit.Parser.tag/3`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#tag/3
[`ExSpirit.Parser.valid_context?/1`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#valid_context?/1
[`ExSpirit.Parser.valid_context_matcher/0`]: https://hexdocs.pm/ex_spirit/ExSpirit.Parser.html#valid_context_matcher/0