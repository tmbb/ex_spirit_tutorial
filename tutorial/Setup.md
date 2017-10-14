# Setup

## Installation

## Preparing to write a parser

ExSpirit expects you to `use` it inside a module, to turn it into a parser module.

$$ include "lib/ex_spirit_tutorial/setup/example_parser.ex"

If you want to to parse text rather than a general stream of things, you need to tell ExSpirit, so that it loads the primitive test parsers (`char()`, `lit()`, etc.):

$$ include "lib/ex_spirit_tutorial/setup/example_text_parser.ex"

This is what you'll be doing most often.

You are now ready to implement [your first parsers](tutorial/PEG Parsers.md).

## Implementation Details - Why `use` instead of `import`?

At this point you might be surprised by having to `use` instead of `import` ExSpirit.
This is indeed an unconventional choice and ir merits some explanation.

In Elixir, there are three main mechanisms of using code defined in other modules:

  * For functions, you can just call the qualified function name (possibly with an alias)For example, you can call the `trim/1` function in the `String` module by writing `String.trim(string)`. This doesn't require the called module to be available at compile-time

  * For macros, you must `import` or `require` the module, so that the macros are available at compile time

  * Finally, you can `use` the module. By writing `use ExternalModule` you allow the external module to define new macros and functions inside your own module. This is actually a simplification: when you use a module the module can do pretty much everything it wants to at compile time, not only define functions and macros, but this level of understanding is enough for what we're after here.

The functions defined when you `use` the module will behave exactly as if they were defined by you using `def` and `defp`. Semantically, it's true that often there isn't such a great difference between `use`ing or `import`ing the module, but there is an important detail. The Module is the fundamental compilation unit for the BEAM. Functions defined in your own module can be optimized more aggressively by the BEAM. Function calls across module can't be optimized at all. When you `use` the module, the functions are defined inside your own module, and you get the benefit of some optimizations.

In the end, the choice to go with `use` instead of `import` was made based on performance alone.
In the case of ExSpirit, this performance increase has been confirmed by benchmarks.
For this reason, you must always `use ExSpirit.Parser` and never `import ExSpirit.Parser`,
because `import ExSpirit.Parser` will not work.

You are now ready to implement [your first parsers](tutorial/PEG Parsers.md).