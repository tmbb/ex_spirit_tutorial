defmodule ExSpiritTutorial.PegGrammarParser do
  use ExSpirit.Parser, text: true

  # !begin: expression
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
  # !end: expression

  # !begin: identifier
  defrule identifier(
    skip() |>
    lexeme(
      seq([
        char([?a..?z, ?A..?Z, ?_]),
        no_skip(chars([?a..?z, ?A..?Z, ?0..?9, ?_], 0))
      ]))
  )
  # !end: identifier

  # !begin: reference
  defrule reference(
    tag(:reference, identifier())
  )
  # !end: reference

  # !begin: sequence
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
  # !end: sequence

  # !begin: zero_or_more
  defrule zero_or_more(
    tag(:zero_or_more,
      seq([
        alt([group(), literal(), regex(), reference()]),
        lit("*")
      ]))
  )
  # !end: zero_or_more

  # !begin: one_or_more
  defrule one_or_more(
    tag(:one_or_more,
      seq([
        alt([group(), literal(), regex(), reference()]),
        lit("+")
      ]))
  )
  # !end: one_or_more

  # !begin: optional
  defrule optional(
    tag(:optional,
      seq([
        alt([group(), literal(), regex(), reference()]),
        lit("?")
      ]))
  )
  # !end: optional

  # !begin: group
  defrule group(
    seq([lit("("), expression(), lit(")")])
  )
  # !end: group

  # !begin: not_ordered_choice
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
  # !end: not_ordered_choice

  # !begin: ordered_choice
  defrule ordered_choice(
    seq([
      not_ordered_choice(),
      repeat(
        seq([lit("/"), not_ordered_choice()]),
        1)
    ])
  ), pipe_result_into: (fn result ->
        {:ordered_choice, List.flatten(result)} end).()
  # !end: ordered_choice

  # !begin: literal
  defrule literal(
    seq([
      lit("\""),
      lexeme(
        repeat(
          lookahead_not(char(?")) |>
          alt([
            seq([char(?\\), char()]),
            char()]))),
      lit("\"")])
  ), pipe_result_into: postprocess_literal
  # !end: literal

  # !begin: postprocess_literal
  defp postprocess_literal(result) do
    {:literal, String.replace(result, "\\\"", "\"")}
  end
  # !end: postprocess_literal

  # !begin: regex
  defrule regex(
    seq([
      lit("~r/"),
      lexeme(
        repeat(
          lookahead_not(char(?/)) |>
          alt([
            seq([char(?\\), char()]),
            char()]))),
      lit("/")])
  ), pipe_result_into: postprocess_regex
  # !end: regex

  # !begin: postprocess_regex
  defp postprocess_regex(result) do
    unescaped = String.replace(result, "\\/", "/")
    pattern = "^" <> unescaped
    regex = Regex.compile!(pattern)
    {:regex, regex}
  end
  # !end: postprocess_regex

  # !begin: rule
  defrule rule(
    seq([
      identifier(), lit("<-"), expression()
    ])
  ), pipe_result_into: (fn [name, body] -> {name, body} end).()
  # !end: rule

  # !begin: rules
  defrule rules(
    seq([
      repeat(rule(), 0),
      ignore(skip()),
      eoi()
    ])
  )
  # !end: rules

  # !begin: example_grammar
  # Taken from a Wikipedia example
  def example_grammar do
    ~S"""
    expr    <- sum
    sum     <- product (("+" / "-") product)*
    product <- value (("*" / "/") value)*
    value   <- ~r/^\d+/ / "(" expr ")"
    """
  end
  # !end: example_grammar

  # !begin: from_string
  def from_string(string) do
    parse(string, rules, skipper: chars([?\s, ?\n, ?\r], 0))
  end
  # !end: from_string
end
