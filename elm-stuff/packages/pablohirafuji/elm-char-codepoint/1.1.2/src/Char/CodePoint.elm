module Char.CodePoint exposing (CodePoint, fromChar, toString, listToString)


{-| Code point operations.


@docs CodePoint, fromChar, toString, listToString
-}


import Char
import Bitwise



{-| CodePoint alias.
-}

type alias CodePoint = Int



{-| Convert from char.
-}

fromChar : Char -> CodePoint
fromChar char =
    let
        charCode = Char.toCode char

        codeUnits =
            String.fromChar char
                |> String.toList

    in
        if charCode >= 55296 && charCode <= 56319 then
            case codeUnits of
                _ :: codeUnit2 :: [] ->
                    keysToCodePoint charCode (Char.toCode codeUnit2)

                _ ->
                    charCode

        else
            charCode


keysToCodePoint : Int -> Int -> Int
keysToCodePoint keyCode1 keyCode2 =
    -- http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
    (keyCode1 - 55296) * 1024 + keyCode2 - 56320 + 65536



{-| Convert to string.
-}

toString : CodePoint -> String
toString codePoint =
    toCharList codePoint
        |> String.fromList



{-| Convert a list of code points to string.
-}

listToString : List CodePoint -> String
listToString codePoints =
    List.concatMap toCharList codePoints
        |> String.fromList


toCharList : CodePoint -> List Char
toCharList codePoint =
    if codePoint <= 65535 then
        [ Char.fromCode codePoint ]

    else
        codePointToKeys codePoint
            |> List.map Char.fromCode


codePointToKeys : Int -> List Int
codePointToKeys codePoint =
    -- http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
    let
        codePoint_ = codePoint - 65536

        highSurrogate =
            (Bitwise.shiftRightBy 10 codePoint_) + 55296

        lowSurrogate =
            (codePoint_ % 1024) + 56320

    in
        [ highSurrogate, lowSurrogate ]

