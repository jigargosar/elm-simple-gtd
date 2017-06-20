# Code Point

Convert char to code point and code point to string, similar to javascript's `String.codePointAt` and `String.fromCodePoint`. [Demo](https://pablohirafuji.github.io/elm-char-codepoint/).

## What's the difference between `Char.toCode` and `Char.CodePoint.fromChar`?

From [MDN](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/String/charCodeAt):

> The `charCodeAt()` method returns an integer between 0 and 65535 representing the UTF-16 code unit at the given index (the UTF-16 code unit matches the Unicode code point for code points representable in a single UTF-16 code unit, but might also be the first code unit of a surrogate pair for code points not representable in a single UTF-16 code unit, e.g. Unicode code points > 0x10000). If you want the entire code point value, use `codePointAt()`.

This mean that not all chars exists in a single 16 bits representation, and `Char.toCode` only returns the first 16 bits code of any given char.

Here is an example to demonstrate how this can affect the output of `Char.toCode` and how `Char.CodePoint.fromChar` fix that:

```elm
Char.toCode '𝔸' == 55349
Char.fromCode 55349 == '�'


Char.CodePoint.fromChar '𝔸' == 120120
Char.CodePoint.toString 120120 == "𝔸"
```

You can try different chars in this [demo](https://pablohirafuji.github.io/elm-char-codepoint/).
