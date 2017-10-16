defmodule ExSpiritTutorial.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_spirit_tutorial,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      markdown_processor: ExDocMakeup,
      markdown_processor_options: [
        lexer_options: %{
          "elixir" => [
            extra_declarations: [],
            extra_def_like: ["defrule"]
          ]
        }
      ],
      extras: [
        "tutorial/Introduction.md",
        "tutorial/Setup.md",
        "tutorial/PEG Parsers.md"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc_makeup, "~> 0.1.2"},
      # {:ex_doc_makeup, path: "../ex_doc_makeup"}
    ]
  end
end
