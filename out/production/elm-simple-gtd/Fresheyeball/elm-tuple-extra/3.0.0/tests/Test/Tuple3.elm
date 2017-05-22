module Test.Tuple3 exposing (tests)

import Tuple3
import Fuzz exposing (Fuzzer)
import Test exposing (Test, describe, fuzz)
import Expect


tuple3 : Fuzzer ( Int, Int, Int )
tuple3 =
    Fuzz.map3 (\a b c -> ( a, b, c )) Fuzz.int Fuzz.int Fuzz.int


tests : Test
tests =
    describe "Tuple3"
        [ describe "sort"
            [ fuzz tuple3 "is idempotent" <|
                (\x ->
                    Expect.equal
                        (x |> Tuple3.sort |> Tuple3.sort)
                        (x |> Tuple3.sort)
                )
            , fuzz tuple3 "commutes with toList" <|
                (\x ->
                    Expect.equal
                        (x |> Tuple3.sort |> Tuple3.toList)
                        (x |> Tuple3.toList |> List.sort)
                )
            ]
        ]
