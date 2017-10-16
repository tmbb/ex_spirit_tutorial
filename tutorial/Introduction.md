# Introduction

ExSpirit is inspired by the [C++ Spirit Library](CppSpirit).
Just like Spirit, it tries to do as many compile-time optimizations as possible, s that the parsers run as fast as possible at compile time.
While this results in faster parsers at runtime, it means ExSpirit parsers are a little slow to compile.

Due to the way ExSpirit is implemented, it can's optimize as aggressively as Spirit, and the fact that it runs on the [BEAM](BEAM) means it will never be as fast as Spirit.
Spirit, being written in C++, doesn't need a runtime system and can optimize all the way down to the CPU instructions.

## Features

There are many parsing libraries, some of them Open Source and some implemented in Elixir.

Many of them are pure [PEG][PEG] (**P**arsing **E**xpression **G**rammar) parsing libraries.
PEG parsers have a limitation, which is that they can only parse [context-free grammars][CFG].
Put simply, a context-free grammar is a grammar in which the decision on what to do next is based on the remaining symbols and not on the symbols that have already been consumed.
You can think of it as a parser that can't use what it has already seen to decide what to do next.

[PEG]: https://en.wikipedia.org/wiki/Parsing_expression_grammar
[CFG]: https://en.wikipedia.org/wiki/Context-free_grammar

Many programming languages are specified by context-free grammars.
Some file formats, such as [JSON][JSON] or [S-Expressions][SExpr] can also be described by context-free languages.
In this tutorial, we will write both a JSON parser and parser for S-Expressions.

[JSON]: https://en.wikipedia.org/wiki/JSON
[SExpr]: https://en.wikipedia.org/wiki/S-expression

ExSpirit is a general parser, which means it can parse basically anything that can be described unambiguously, including context-sensitive languages.
You can think of context-sensitive languages as languages in which the parser can use the symbols it has already seen in order to decide what to do next.

Basically almost every programming language or file format that is sensitive to indentation is a context-sensitive language.
Examples of context-sensitive languages are some programming languages (e.g. Haskell, Python), some template languages ([Pug][Pug] or [Slim][Slim], both of which have Elixir implementations), and some file formats, such as [XML][XML] and [YAML][XML].
[HTML][HTML], while being based in XML, is in a league of its own, and HTML5, the latest iteration, [can't even be defined by a meaningful grammar](http://trevorjim.com/a-grammar-for-html5/).
In this tutorial, we will write an XML parser.

## Alternative Approaches

ExSpirit is modeled on the [C++ Spirit Library](CppSpirit).

There are other approaches to parsing, namely:

  * Parser Generators
  * Monadic parsing
  * Parsers that split the input into tokens with a *lexer* and feed the token stream to te actual *parser*

## Further Resources

The ExSpirit docs provide a good overview of the API, and document all the primitive parsers and parser combinators.
The goal of this tutorial is to guide your hand over most of the features so that you know how to use the parsers in practice.

[Pug]: https://pugjs.org/api/getting-started.html
[Slim]: http://slim-lang.com/
[Haskell]: https://www.haskell.org/
[Python]: https://www.python.org/
[XML]: https://en.wikipedia.org/wiki/XML
[YAML]: https://en.wikipedia.org/wiki/YAML
[HTML]: https://en.wikipedia.org/wiki/HTML
[CppSpirit]: http://www.boost.org/doc/libs/1_65_1/libs/spirit/doc/html/index.html