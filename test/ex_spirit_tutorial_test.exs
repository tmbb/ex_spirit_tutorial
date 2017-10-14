defmodule ExSpiritTutorialTest do
  use ExUnit.Case
  doctest ExSpiritTutorial

  test "greets the world" do
    assert ExSpiritTutorial.hello() == :world
  end
end
