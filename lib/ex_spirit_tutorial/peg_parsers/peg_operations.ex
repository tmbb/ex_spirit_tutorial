defmodule ExSpiritTutorial.PegParsers.PegOperations do
  use ExSpirit.Parser, text: true

  defrule e1(
    char(?x))

  defrule e2(
    char(?y))

  defrule e(
    char(?a))
end