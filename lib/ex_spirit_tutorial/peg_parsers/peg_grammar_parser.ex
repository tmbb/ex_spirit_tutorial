defmodule ExSpiritTutorial.PEGGrammarParser do
  use ExSpirit.Parser, text: true

  defrule identifier(
    skip() |>
    lexeme(
      seq([
        char([?a..?z, ?A..?Z, ?_]),
        no_skip(
          chars([?a..?z, ?A..?Z, ?0..?9, ?_], 0))
      ]))
  )

  defrule reference(
    tag(:reference, identifier())
  )

  defrule sequence(
    tag(:sequence,
      repeat(
        alt([
          zero_or_more(),
          one_or_more(),
          optional(),
          group(),
          literal(),
          regex(),
          reference()
        ]) |> lookahead_not(lit("<-")), 2))
  )

  defrule zero_or_more(
    tag(:zero_or_more,
      seq([
        alt([
          group(),
          literal(),
          regex(),
          reference()
        ]),
        lit("*")
      ]))
  )

  defrule one_or_more(
    tag(:one_or_more,
      seq([
        alt([
          group(),
          literal(),
          regex(),
          reference()
        ]),
        lit("+")
      ]))
  )

  defrule optional(
    tag(:optional,
      seq([
        alt([
          group(),
          literal(),
          regex(),
          reference()
        ]),
        lit("?")
      ]))
  )

  defrule group(
    seq([
      lit("("),
      expression(),
      lit(")")
    ])
  )

  defrule not_ordered_choice(
    alt([
      sequence(),
      zero_or_more(),
      one_or_more(),
      optional(),
      group(),
      literal(),
      regex(),
      reference()
    ])
  )

  defrule ordered_choice(
    seq([
      not_ordered_choice(),
      repeat(
        seq([
          lit("/"),
          not_ordered_choice()
        ]), 1)
    ])
  ), pipe_result_into: (fn result ->
        {:ordered_choice, List.flatten(result)} end).()

  defrule expression(
    alt([
      ordered_choice(),
      sequence(),
      zero_or_more(),
      one_or_more(),
      optional(),
      group(),
      literal(),
      regex(),
      reference()
    ])
  )

  defrule literal(
    seq([
      lit("\""),
      lexeme(
        repeat(
          lookahead_not(char(?")) |>
          alt([
            seq([
              char(?\\),
              char()]),
            char()]))),
      lit("\"")])
  ), pipe_result_into: postprocess_literal

  defp postprocess_literal(result) do
    {:literal, String.replace(result, "\\\"", "\"")}
  end

  defrule regex(
    seq([
      lit("~r/"),
      lexeme(
        repeat(
          lookahead_not(char(?/)) |>
          alt([
            seq([
              char(?\\),
              char()]),
            char()]))),
      lit("/")])
  ), pipe_result_into: postprocess_regex

  def postprocess_regex(result) do
    unescaped = String.replace(result, "\\/", "/")
    pattern = "^" <> unescaped
    regex = Regex.compile!(pattern)
    {:regex, regex}
  end

  defrule rule(
    seq([
      identifier(),
      lit("<-"),
      expression()
    ])
  ), pipe_result_into: (fn [name, body] -> {name, body} end).()

  defrule rules(
    seq([
      repeat(rule(), 0),
      ignore(skip()),
      eoi()
    ])
  )

  # Taken from a Wikipedia example
  def example_grammar do
    ~S"""
    expr    <- sum
    sum     <- product (("+" / "-") product)*
    product <- value (("*" / "/") value)*
    value   <- ~r/\d+/ / "(" expr ")"
    """
  end

  def from_string(string) do
    parse(string, rules, skipper: chars([?\s, ?\n, ?\r], 0))
  end
end
