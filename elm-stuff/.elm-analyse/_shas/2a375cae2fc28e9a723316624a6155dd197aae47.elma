module RegexBuilder
    exposing
        ( Pattern
        , char
        , exactly
        , remember
        , either
        , oneOf
        , noneOf
        , maybe
        , many
        , digit
        , noDigit
        , whiteSpace
        , noWhiteSpace
        , anyChar
        , toRegexString
        , toRegex
        )

{-| Build a regex from composable `Pattern`s.

# Definition
@docs Pattern

# Primitives
@docs char, exactly, oneOf, noneOf

# Combinators
@docs maybe, many, either, remember

# Evaluate
@docs toRegexString, toRegex

# Character classes
@docs anyChar, whiteSpace, noWhiteSpace, digit, noDigit

-}

import Regex exposing (regex, Regex)
import Internal exposing (Internal(..), internalToString, Quantifier(..))


{-| A `Pattern` is just a function from some internal state to another,
describing a regex in the process.
The most important part to take away from that:
You can **combine `Pattern`s using `>>`.**

    char 'a' >> char 'b' == exactly "ab"
-}
type alias Pattern =
    Internal -> Internal


{-| Matches a single character.
-}
char : Char -> Pattern
char =
    Unescaped


{-| Matches the given string.
-}
exactly : String -> Pattern
exactly s =
    s
        |> String.toList
        |> List.map Unescaped
        |> List.foldr (>>) identity


{-| When working with `Match`es, you need `remember` to make subpatterns.
I recommend using this with named `Pattern`s:

    hexNumber : Pattern
    hexNumber =
        let
            hexDigit =
                either
                    [ digit
                    , oneOf [ 'A','B','C','D','E','F' ]
                    ]
        in
            exactly "0x"
                >> remember (many hexDigit)
-}
remember : Pattern -> Pattern
remember f =
    case f Empty of
        Empty ->
            identity

        x ->
            Remember x


{-| Introduce alternatives.

    -- corresponds to the regex `a|b`
    either [char 'a', char 'b']
-}
either : List Pattern -> Pattern
either fs =
    let
        flatten x rs =
            case (x Empty) of
                Choice ys Empty ->
                    ys
                        |> List.filter (flip List.member rs)
                        |> (++) rs

                y ->
                    if List.member y rs then
                        rs
                    else
                        y :: rs
    in
        fs
            |> List.foldr flatten []
            |> Choice


{-| Matches one of the given characters.
-}
oneOf : List Char -> Pattern
oneOf cs =
    case cs of
        [] ->
            identity

        _ ->
            OneOf cs


{-| Matches none of the given characters.
-}
noneOf : List Char -> Pattern
noneOf =
    NoneOf


{-| Matches the given `Pattern` 0 or 1 time.
-}
maybe : Pattern -> Pattern
maybe f i =
    case f Empty of
        Postfix ZeroOrOne x Empty ->
            Postfix ZeroOrOne x i

        Postfix _ x Empty ->
            -- OnePlus or ZeroPlus goes here
            Postfix ZeroPlus x i

        Empty ->
            i

        _ ->
            Postfix ZeroOrOne (f Empty) i


{-| Matches the given `Pattern` *1 or more* times.
If you are looking for 0 or more repetitions, combine this with maybe:

    zeroOrMoreAs = maybe (many (char 'a'))

Note: When you turn this combination into a String or Regex, this will be transformed into a single "0 or more"
operator. So don't be afraid to use it like this!
-}
many : Pattern -> Pattern
many f i =
    case f Empty of
        Postfix OnePlus x Empty ->
            Postfix OnePlus x i

        Postfix _ x Empty ->
            Postfix ZeroPlus x i

        Empty ->
            i

        _ ->
            Postfix OnePlus (f Empty) i


{-| Matches a single decimal digit.
-}
digit : Pattern
digit =
    Raw "\\d"


{-| Matches anything but a decimal digit.
-}
noDigit : Pattern
noDigit =
    Raw "\\D"


{-| Matches a single white space character, including (but not limited to)
space, tab, form feed and line feed.
-}
whiteSpace : Pattern
whiteSpace =
    Raw "\\s"


{-| Opposite of `whiteSpace`.
-}
noWhiteSpace : Pattern
noWhiteSpace =
    Raw "\\S"


{-| Matches any character *except newline*.
-}
anyChar : Pattern
anyChar =
    Raw "."


{-| Gives the string representation of the given `Pattern`.

    either
        [ char 'a'
        , char 'b'
        ]
        |> toRegexString
    ==
        "a|b"
-}
toRegexString : Pattern -> String
toRegexString f =
    internalToString (f Empty)


{-| Turn the `Pattern` into a Regex.
-}
toRegex : Pattern -> Regex
toRegex =
    toRegexString
        >> regex
