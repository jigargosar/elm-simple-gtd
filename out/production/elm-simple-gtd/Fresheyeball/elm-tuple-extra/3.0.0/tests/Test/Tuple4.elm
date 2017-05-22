module Test.Tuple4 exposing (tests)

import Tuple4
import Fuzz exposing (Fuzzer)
import Test exposing (Test, describe, fuzz)
import Expect


tuple4 : Fuzzer ( Int, Int, Int, Int )
tuple4 =
    Fuzz.map4 (\a b c d -> ( a, b, c, d )) Fuzz.int Fuzz.int Fuzz.int Fuzz.int


tests : Test
tests =
    describe "Tuple4"
        [ describe "sort"
            [ fuzz tuple4 "is idempotent" <|
                (\x ->
                    Expect.equal
                        (x |> Tuple4.sort |> Tuple4.sort)
                        (x |> Tuple4.sort)
                )
            , fuzz tuple4 "commutes with toList" <|
                (\x ->
                    Expect.equal
                        (x |> Tuple4.sort |> Tuple4.toList)
                        (x |> Tuple4.toList |> List.sort)
                )
            ]
        ]
