module DictExtraTests exposing (..)

import Fuzz exposing (Fuzzer)
import DictList exposing (..)
import Expect
import Test exposing (..)
import Set


{-| Fuzz a DictList, given a fuzzer for the keys and values.
-}
fuzzDictList : Fuzzer comparable -> Fuzzer value -> Fuzzer (DictList comparable value)
fuzzDictList fuzzKey fuzzValue =
    Fuzz.tuple ( fuzzKey, fuzzValue )
        |> Fuzz.list
        |> Fuzz.map DictList.fromList


fuzzIntList : Fuzzer (List Int)
fuzzIntList =
    Fuzz.list Fuzz.int


threeElementList =
    (fromList [ ( 1, 1 ), ( 2, 2 ), ( 3, 3 ) ])


dictExtraUnitTests : Test
dictExtraUnitTests =
    describe "Dict Extra Unittests"
        [ describe "groupBy"
            [ test "empty" <| \() -> Expect.equal (groupBy identity []) empty
            , test "always equal elements" <| \() -> Expect.equal (groupBy (always 1) [ 1, 2, 3 ]) (fromList [ ( 1, [ 1, 2, 3 ] ) ])
            , test "map to original key" <| \() -> Expect.equal (groupBy identity [ 1, 2, 3 ]) (fromList [ ( 3, [ 3 ] ), ( 2, [ 2 ] ), ( 1, [ 1 ] ) ])
            , test "odd-even" <| \() -> Expect.equal (groupBy (\v -> v % 2) [ 1, 2, 3 ]) (fromList [ ( 1, [ 1, 3 ] ), ( 0, [ 2 ] ) ])
            ]
        , describe "fromListBy"
            [ test "empty" <| \() -> Expect.equal (fromListBy identity []) empty
            , test "simple list" <| \() -> Expect.equal (fromListBy (\v -> v + 1) [ 1, 2, 3 ]) (fromList [ ( 2, 1 ), ( 3, 2 ), ( 4, 3 ) ])
            ]
        , describe "removeWhen"
            [ test "empty" <| \() -> Expect.equal (removeWhen (\k v -> True) empty) empty
            , test "remove all" <| \() -> Expect.equal (removeWhen (\k v -> True) (fromList [ ( 1, 1 ), ( 2, 2 ), ( 3, 3 ) ])) empty
            , test "remove none" <| \() -> Expect.equal (removeWhen (\k v -> False) (fromList [ ( 1, 1 ), ( 2, 2 ), ( 3, 3 ) ])) (fromList [ ( 1, 1 ), ( 2, 2 ), ( 3, 3 ) ])
            ]
        , describe "removeMany"
            [ test "empty" <| \() -> Expect.equal (removeMany (Set.fromList [ 1, 2 ]) empty) empty
            , test "remove none element" <| \() -> Expect.equal (removeMany (Set.fromList [ 4 ]) threeElementList) threeElementList
            , test "remove one element" <| \() -> Expect.equal (removeMany (Set.fromList [ 1 ]) threeElementList) (DictList.filter (\k v -> k /= 1) threeElementList)
            , test "remove two elements" <| \() -> Expect.equal (removeMany (Set.fromList [ 1, 2 ]) threeElementList) (DictList.filter (\k v -> k == 3) threeElementList)
            , test "remove all elements" <| \() -> Expect.equal (removeMany (Set.fromList [ 1, 2, 3 ]) threeElementList) empty
            ]
        , describe "keepOnly"
            [ test "empty" <| \() -> Expect.equal (keepOnly (Set.fromList [ 1, 2 ]) empty) empty
            , test "keep none element" <| \() -> Expect.equal (removeMany (Set.fromList [ 4 ]) threeElementList) threeElementList
            , test "keep one element" <| \() -> Expect.equal (keepOnly (Set.fromList [ 1 ]) threeElementList) (DictList.filter (\k v -> k == 1) threeElementList)
            , test "keep two elements" <| \() -> Expect.equal (keepOnly (Set.fromList [ 1, 2 ]) threeElementList) (DictList.filter (\k v -> k /= 3) threeElementList)
            , test "keep all elements" <| \() -> Expect.equal (keepOnly (Set.fromList [ 1, 2, 3 ]) threeElementList) threeElementList
            ]
        , describe "mapKeys"
            [ test "empty" <| \() -> Expect.equal (mapKeys toString empty) empty
            , test "toString mapping" <| \() -> Expect.equal (mapKeys toString threeElementList) (fromList [ ( "1", 1 ), ( "2", 2 ), ( "3", 3 ) ])
            ]
        ]


dictExtraFuzzTests : Test
dictExtraFuzzTests =
    -- @TODO Expand the fuzz tests
    describe "Dict extra fuzz tests"
        [ fuzz fuzzIntList "groupBy (total length doesn't change)" <|
            \subject ->
                Expect.equal (List.length subject)
                    (groupBy (\v -> v % 2) subject
                        |> toList
                        |> List.map (\( k, v ) -> List.length v)
                        |> List.foldr (+) 0
                    )
        , fuzz fuzzIntList "groupBy (no elements dissapear)" <|
            \subject ->
                Expect.equal
                    (Set.diff (Set.fromList subject)
                        (Set.fromList
                            (groupBy (\v -> v % 2) subject
                                |> toList
                                |> List.foldr (\( k, v ) agg -> List.append v agg) []
                            )
                        )
                    )
                    (Set.fromList [])
        ]
