defmodule ExSpiritTutorial.Utils do
  def format_link({module, function, arity}) do
    m = module |> Atom.to_string |> String.trim_leading("Elixir.")
    f = Atom.to_string(function)
    "[`#{m}.#{f}/#{arity}`]: https://hexdocs.pm/ex_spirit/#{m}.html##{f}/#{arity}"
  end

  def links_for_module(module) do
    (module.__info__(:functions) ++ module.__info__(:macros))
    |> Enum.map(fn {f, a} -> {module, f, a} end)
    |> Enum.map(&format_link/1)
  end

  def gen_links() do
    [ExSpirit.Parser, ExSpirit.Parser.Text]
    |> Enum.map(&links_for_module/1)
    |> List.flatten
    |> Enum.sort
    |> Enum.join("\n")
  end
end