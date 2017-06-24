## Some basic helpers for generating CSS style declarations in Elm

CSS style declarations are key-value pairs consisting of a property name and a
value assigned to that property. When working with styles in Elm, it is
sometimes desirable to write a function that takes a CSS value, performs a
calculation, and returns the modified value. This library allows for a basic
type differentiation of CSS values so that type-mismatch errors can be handled
more easily.

For example, suppose you want to write a function that takes a background color
and returns a suitable foreground color. If the background color were stored as
a string, you would have to parse the string in order to determine whether it
properly encodes a color value, handling any type conversion errors in the
process. The advantage of using the `CssBasics` package in this case is that it
gives you a convenient way of storing the color value as a `Color` and
converting it to a string only when the style declaration is rendered. So when
writing a function like the example above, error handling can be performed with
simple pattern matching — if the `CssValue` supplied is of the `Col` type,
perform the calculation, otherwise return a default value.

__Dependencies:__
- [elm-lang/core/5.0.0](http://package.elm-lang.org/packages/elm-lang/core/5.0.0)
- [elm-lang/html/2.0.0](http://package.elm-lang.org/packages/elm-lang/html/2.0.0)

__Extensions:__
- [danielnarey/elm-stylesheet](http://package.elm-lang.org/packages/danielnarey/elm-stylesheet/latest)
- [danielnarey/elm-css-math](http://package.elm-lang.org/packages/danielnarey/elm-css-math/latest)
