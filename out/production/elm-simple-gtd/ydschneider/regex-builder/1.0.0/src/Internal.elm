module Internal exposing (..)


type Internal
    = Remember Internal Internal
    | OneOf (List Char) Internal
    | NoneOf (List Char) Internal
    | Choice (List Internal) Internal
    | Postfix Quantifier Internal Internal
    | Lookahead Internal Internal
    | NegativeLookahead Internal Internal
    | Raw String Internal
    | Unescaped Char Internal
    | Empty



{-
   Assumptions : Raw only contains sequences that should be treated as one symbol (\d etc.)

-}


type Quantifier
    = ZeroPlus
    | OnePlus
    | ZeroOrOne
    | Exactly Int
    | Between Int Int
    | LazyZeroPlus
    | LazyOnePlus
    | LazyZeroOrOne
    | LazyBetween Int Int


quantifierToString : Quantifier -> String
quantifierToString q =
    case q of
        ZeroPlus ->
            "*"

        OnePlus ->
            "+"

        ZeroOrOne ->
            "?"

        Exactly x ->
            "{" ++ toString x ++ "}"

        Between i j ->
            "{" ++ toString i ++ "," ++ toString j ++ "}"

        LazyZeroPlus ->
            "*?"

        LazyOnePlus ->
            "+?"

        LazyZeroOrOne ->
            "??"

        LazyBetween i j ->
            "{" ++ toString i ++ "," ++ toString j ++ "}?"


specialChars : List Char
specialChars =
    [ '-', '/', '\\', '^', '$', '*', '+', '#', '?', '.', '(', ')', '|', '[', ']', '{', '}' ]


replaceNonPrinting : Char -> String
replaceNonPrinting c =
    case c of
        '\x0C' ->
            "\\f"

        '\n' ->
            "\\n"

        '\x0D' ->
            "\\r"

        '\t' ->
            "\\t"

        '\x0B' ->
            "\\v"

        '\x08' ->
            "[\\b]"

        _ ->
            String.fromChar c


escape : Char -> String
escape c =
    if List.member c specialChars then
        "\\" ++ String.fromChar c
    else
        replaceNonPrinting c


escapeOneOf : Char -> String
escapeOneOf c =
    if c == '\\' then
        "\\\\"
    else if c == '\x08' then
        -- special case for backspace so there are no nested []
        "\\b"
    else if List.member c [ '[', ']', '-' ] then
        "\\" ++ String.fromChar c
    else
        replaceNonPrinting c


quantify : Quantifier -> Internal -> String
quantify q x =
    let
        needsParens =
            case x of
                Unescaped _ Empty ->
                    False

                Raw _ Empty ->
                    False

                Empty ->
                    False

                NoneOf _ Empty ->
                    False

                OneOf _ Empty ->
                    False

                Remember _ Empty ->
                    False

                _ ->
                    True
    in
        if needsParens then
            "(?:"
                ++ internalToString x
                ++ ")"
                ++ quantifierToString q
        else
            internalToString x ++ quantifierToString q


internalToString : Internal -> String
internalToString x =
    let
        appendTo a =
            String.append <|
                case a of
                    -- only Choice binds less than concatenation
                    Choice _ _ ->
                        "(?:" ++ internalToString a ++ ")"

                    _ ->
                        internalToString a
    in
        case x of
            Remember r i ->
                "("
                    ++ internalToString r
                    ++ ")"
                    |> appendTo i

            OneOf cs i ->
                cs
                    |> List.map escapeOneOf
                    |> String.concat
                    |> (\s -> "[" ++ s ++ "]")
                    |> appendTo i

            NoneOf cs i ->
                cs
                    |> List.map escapeOneOf
                    |> String.concat
                    |> (\s -> "[^" ++ s ++ "]")
                    |> appendTo i

            Choice xs i ->
                let
                    wrap s =
                        if i /= Empty && List.length xs > 1 then
                            "(?:" ++ s ++ ")"
                        else
                            s
                in
                    xs
                        |> List.map internalToString
                        |> String.join "|"
                        |> wrap
                        |> appendTo i

            Postfix q r i ->
                quantify q r
                    |> appendTo i

            Lookahead x y ->
                "(?:"
                    ++ internalToString y
                    ++ ")(?="
                    ++ internalToString x
                    ++ ")"

            NegativeLookahead x y ->
                "(?:"
                    ++ internalToString y
                    ++ ")(?!"
                    ++ internalToString x
                    ++ ")"

            Raw s i ->
                appendTo i s

            Unescaped c i ->
                appendTo i (escape c)

            Empty ->
                ""
