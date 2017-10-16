defmodule ExSpiritTutorial.PegParsers.PegGrammarCompiler do

  defmodule M do
    @moduledoc false
    use ExSpirit.Parser, text: true
  end

  def compile_expression({:reference, reference}) do
    quote do
      unquote(String.to_atom(reference))()
    end
  end

  def compile_expression({:sequence, sequence}) do
    children = Enum.map(sequence, &compile_expression/1)
    quote do
      M.seq(unquote(children))
    end
  end

  def compile_expression({:ordered_choice, choices}) do
    children = Enum.map(choices, &compile_expression/1)
    quote do
      M.alt(unquote(children))
    end
  end

  def compile_expression({:zero_or_more, parser}) do
    quote do
      M.repeat(unquote(parser), 0)
    end
  end

  def compile_expression({:one_or_more, parser}) do
    quote do
      M.repeat(unquote(parser), 1)
    end
  end

  def compile_expression({:optional, parser}) do
    quote do
      M.alt([
        unquote(parser),
        M.success(nil)
      ])
    end
  end

  def compile_expression({:literal, literal}) do
    quote do
      M.lit(unquote(literal))
    end
  end

end

defmodule Lambda do
  defmacro λ(ast) do
    quote do
      &(unquote(ast))
    end
  end
end

defmodule GreekStatistics do
  def σ(xs) do
    n = length(xs)
    μ = μ(xs)
    Enum.sum(for x <- xs, do: (x - μ)*(x - μ)) / (n*n)
  end

  def μ(xs) do
    n = length(xs)
    Enum.sum(xs) / n
  end
end