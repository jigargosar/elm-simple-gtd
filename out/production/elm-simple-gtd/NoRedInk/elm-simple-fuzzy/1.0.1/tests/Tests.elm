module Tests exposing (..)

import Test exposing (..)
import Expect exposing (Expectation, equal)
import Simple.Fuzzy exposing (match, root, filter)


all : Test
all =
    Test.concat
        [ matchTests
        , filterTests
        , rootTests
        ]


matchTests : Test
matchTests =
    Test.describe "Simple.Fuzzy.match"
        [ Test.describe "should match"
            [ test "when no needle" <|
                \() -> match "" "word" |> equal True
            , test "when single letter starts haystack" <|
                \() -> match "w" "word" |> equal True
            , test "when single letter is in haystack" <|
                \() -> match "o" "word" |> equal True
            , test "when multiple letters start haystack" <|
                \() -> match "wo" "word" |> equal True
            , test "when multiple letters are in haystack" <|
                \() -> match "or" "word" |> equal True
            , test "when multiple letters spread throughout word" <|
                \() -> match "od" "word" |> equal True
            , test "when needle exactly matches haystack" <|
                \() -> match "word" "word" |> equal True
            , test "even when cases do not" <|
                \() -> match "wOrD" "woRd" |> equal True
            , test "even when punctuation does not" <|
                \() -> match "wOr,D" "w,ord" |> equal True
            , test "even when spaces do not" <|
                \() -> match "lst" "its a list" |> equal True
            ]
        , Test.describe "should not match"
            [ test "when needle letters are not in right order" <|
                \() -> match "ro" "word" |> equal False
            , test "when needle letters are duplicated" <|
                \() -> match "rr" "word" |> equal False
            ]
        ]


filterTests : Test
filterTests =
    Test.describe "Simple.Fuzzy.filter"
        [ test "filters for all the matching strings" <|
            \() -> Simple.Fuzzy.filter .name "el" dummyList |> equal expectedList
        ]


type alias Language =
    { name : String }


dummyList : List Language
dummyList =
    [ Language "Elm"
    , Language "Javascript"
    , Language "Ruby"
    , Language "Elixir"
    , Language "Ruby"
    ]


expectedList : List Language
expectedList =
    [ Language "Elm"
    , Language "Elixir"
    ]


rootTests : Test
rootTests =
    Test.describe "Simple.Fuzzy.root"
        [ Test.describe "should break a word down to its canonical self"
            [ test "with an empty string" <|
                \() -> root "" |> equal ""
            , test "with a single letter" <|
                \() -> root "a" |> equal "a"
            , test "with many letters" <|
                \() -> root "abc" |> equal "abc"
            , test "with some capital letters" <|
                \() -> root "aBc" |> equal "abc"
            , test "with some capital letters" <|
                \() -> root "Aaron" |> equal "aaron"
            , test "with some punctuation and spaces letters" <|
                \() -> root "abc!! f" |> equal "abcf"
            ]
        ]
