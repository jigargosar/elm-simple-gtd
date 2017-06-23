module RegexBuilder.Extra
    exposing
        ( repeat
        , between
        , maybeLazy
        , manyLazy
        , betweenLazy
        , Options
        , defaultOptions
        , toRegexString
        , toRegex
        , wordBoundary
        , noWordBoundary
        , ifFollowedBy
        , ifNotFollowedBy
        )

{-| If you find yourself being too limited by [RegexBuilder](#RegexBuilder),
this might help you out. However, some functions in this module will likely add more parenthesis
than needed to the resulting expression.

# Repitition
@docs repeat, between

# Laziness
By default, a pattern consumes as many characters as possible (greedy matching).
Use these if you need lazy (non-greedy) matching.
@docs maybeLazy, manyLazy, betweenLazy

# Alignment
@docs Options, defaultOptions, toRegexString, toRegex, wordBoundary, noWordBoundary

# Lookahead
@docs ifFollowedBy, ifNotFollowedBy
-}

import RegexBuilder exposing (Pattern)
import Internal exposing (Internal(..), Quantifier(..), internalToString)
import Regex exposing (Regex, regex)


{-| The equivalents of `^` and `$`.
-}
type alias Options =
    { alignBeginning : Bool
    , alignEnd : Bool
    }


{-|
    defaultOptions =
        { alignBeginning = False
        , alignEnd = False
        }
-}
defaultOptions : Options
defaultOptions =
    { alignBeginning = False
    , alignEnd = False
    }


{-|
-}
toRegexString : Options -> Pattern -> String
toRegexString { alignBeginning, alignEnd } f =
    let
        begin =
            if alignBeginning then
                "^"
            else
                ""

        end =
            if alignEnd then
                "$"
            else
                ""
    in
        begin ++ RegexBuilder.toRegexString f ++ end


{-|
-}
toRegex : Options -> Pattern -> Regex
toRegex o =
    toRegexString o
        >> regex


{-| `a >> ifFollowedBy b` matches `a` only if it is followed by `b`, but doesn't include `b` in the match
-}
ifFollowedBy : Pattern -> Pattern
ifFollowedBy f =
    Lookahead (f Empty)


{-|
-}
ifNotFollowedBy : Pattern -> Pattern
ifNotFollowedBy f =
    NegativeLookahead (f Empty)


{-| Matches at the beginning or end of a word.
Note that a word is anything consisting of some of A-Z, a-z, 0-9 and underscore.
If you are dealing with Unicode, this might not be the behavior you want.
-}
wordBoundary : Pattern
wordBoundary =
    Raw "\\b"


{-|
-}
noWordBoundary : Pattern
noWordBoundary =
    Raw "\\B"


{-| Repeat a `Pattern`.
Given a 0 or a negative number, this will result in an empty subpattern:

    char 'a'
        >> repeat -1 char'b'
        >> char 'c'

    ==

    char 'a'
        >> char 'c'
-}
repeat : Int -> Pattern -> Pattern
repeat i f =
    if i <= 0 then
        identity
    else
        Postfix (Exactly i) (f Empty)


{-| `between i j pattern` will match `pattern` at least `i` and at most `j` times.
Invalid parameters `i`, `j` will result in empty subpatterns as shown above.
-}
between : Int -> Int -> Pattern -> Pattern
between i j f =
    if i > j || i < 0 || j < 0 then
        identity
    else if i == j then
        Postfix (Exactly i) (f Empty)
    else
        Postfix (Between i j) (f Empty)


{-|
-}
maybeLazy : Pattern -> Pattern
maybeLazy f =
    Postfix LazyZeroOrOne (f Empty)


{-|
-}
manyLazy : Pattern -> Pattern
manyLazy f =
    Postfix LazyOnePlus (f Empty)


{-|
-}
betweenLazy : Int -> Int -> Pattern -> Pattern
betweenLazy i j f =
    if i > j || i < 0 || j < 0 then
        identity
    else if i == j then
        Postfix (Exactly i) (f Empty)
    else
        Postfix (LazyBetween i j) (f Empty)
