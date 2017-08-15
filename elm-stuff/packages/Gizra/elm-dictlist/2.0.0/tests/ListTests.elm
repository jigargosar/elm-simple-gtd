module ListTests exposing (..)

{-| This is an adaptation of the `List` tests in elm-lang/core, in order
to test whether we are a well-behaved list.
-}

import Test exposing (..)
import Expect exposing (Expectation)
import Maybe exposing (Maybe(Nothing, Just))
import DictList exposing (..)


tests : Test
tests =
    describe "List Tests"
        [ testListOfN 0
        , testListOfN 1
        , testListOfN 2
        , testListOfN 5000
        ]


toDictList : List comparable -> DictList comparable comparable
toDictList =
    List.map (\a -> ( a, a )) >> DictList.fromList


testListOfN : Int -> Test
testListOfN n =
    let
        xs =
            List.range 1 n |> toDictList

        xsOpp =
            List.range -n -1 |> toDictList

        xsNeg =
            foldl cons empty xsOpp

        -- assume foldl and (::) work
        zs =
            List.range 0 n
                |> List.map (\a -> ( a, a ))
                |> DictList.fromList

        sumSeq k =
            k * (k + 1) // 2

        xsSum =
            sumSeq n

        mid =
            n // 2
    in
        describe (toString n ++ " elements")
            [ describe "foldl"
                [ test "order" <| \() -> Expect.equal (n) (foldl (\_ x acc -> x) 0 xs)
                , test "total" <| \() -> Expect.equal (xsSum) (foldl (always (+)) 0 xs)
                ]
            , describe "foldr"
                [ test "order" <| \() -> Expect.equal (min 1 n) (foldr (\_ x acc -> x) 0 xs)
                , test "total" <| \() -> Expect.equal (xsSum) (foldl (always (+)) 0 xs)
                ]
            , describe "map"
                [ test "identity" <| \() -> Expect.equal (xs) (map (always identity) xs)
                , test "linear" <| \() -> Expect.equal (List.range 2 (n + 1)) (values <| map (always ((+) 1)) xs)
                ]
            , test "isEmpty" <| \() -> Expect.equal (n == 0) (isEmpty xs)
            , test "length" <| \() -> Expect.equal (n) (length xs)
            , test "reverse" <| \() -> Expect.equal (xsOpp) (reverse xsNeg)
            , describe "member"
                [ test "positive" <| \() -> Expect.equal (True) (member n zs)
                , test "negative" <| \() -> Expect.equal (False) (member (n + 1) xs)
                ]
            , test "head" <|
                \() ->
                    if n == 0 then
                        Expect.equal (Nothing) (head xs)
                    else
                        Expect.equal (Just ( 1, 1 )) (head xs)
            , describe "List.filter"
                [ test "none" <| \() -> Expect.equal (empty) (DictList.filter (\_ x -> x > n) xs)
                , test "one" <| \() -> Expect.equal [ n ] (values <| DictList.filter (\_ z -> z == n) zs)
                , test "all" <| \() -> Expect.equal (xs) (DictList.filter (\_ x -> x <= n) xs)
                ]
            , describe "take"
                [ test "none" <| \() -> Expect.equal (empty) (take 0 xs)
                , test "some" <| \() -> Expect.equal (List.range 0 (n - 1)) (values <| take n zs)
                , test "all" <| \() -> Expect.equal (xs) (take n xs)
                , test "all+" <| \() -> Expect.equal (xs) (take (n + 1) xs)
                ]
            , describe "drop"
                [ test "none" <| \() -> Expect.equal (xs) (drop 0 xs)
                , test "some" <| \() -> Expect.equal [ n ] (values <| drop n zs)
                , test "all" <| \() -> Expect.equal (empty) (drop n xs)
                , test "all+" <| \() -> Expect.equal (empty) (drop (n + 1) xs)
                ]
              -- append works differently in `DictList` because it overwrites things with the same keys
            , test "append" <| \() -> Expect.equal (xsSum {- * 2 -}) (append xs xs |> foldl (always (+)) 0)
            , test "cons" <| \() -> Expect.equal (values <| append (toDictList [ -1 ]) xs) (values <| cons -1 -1 xs)
            , test "List.concat" <| \() -> Expect.equal (append xs (append zs xs)) (DictList.concat [ xs, zs, xs ])
            , describe "partition"
                [ test "left" <| \() -> Expect.equal ( xs, empty ) (partition (\_ x -> x > 0) xs)
                , test "right" <| \() -> Expect.equal ( empty, xs ) (partition (\_ x -> x < 0) xs)
                , test "split" <| \() -> Expect.equal ( List.range (mid + 1) n |> toDictList, List.range 1 mid |> toDictList ) (partition (\_ x -> x > mid) xs)
                ]
            , describe "filterMap"
                [ test "none" <| \() -> Expect.equal (empty) (filterMap (\_ x -> Nothing) xs)
                , test "all" <| \() -> Expect.equal (values xsNeg) (values <| filterMap (\_ x -> Just -x) xs)
                , let
                    halve x =
                        if x % 2 == 0 then
                            Just (x // 2)
                        else
                            Nothing
                  in
                    test "some" <| \() -> Expect.equal (List.range 1 mid) (values <| filterMap (always halve) xs)
                ]
            , test "sum" <| \() -> Expect.equal (xsSum) (sum xs)
            , test "product" <| \() -> Expect.equal (0) (product zs)
            , test "maximum" <|
                \() ->
                    if n == 0 then
                        Expect.equal (Nothing) (maximum xs)
                    else
                        Expect.equal (Just n) (maximum xs)
            , test "minimum" <|
                \() ->
                    if n == 0 then
                        Expect.equal (Nothing) (minimum xs)
                    else
                        Expect.equal (Just 1) (minimum xs)
            , describe "all"
                [ test "false" <| \() -> Expect.equal (False) (all (\_ z -> z < n) zs)
                , test "true" <| \() -> Expect.equal (True) (all (\_ x -> x <= n) xs)
                ]
            , describe "any"
                [ test "false" <| \() -> Expect.equal (False) (any (\_ x -> x > n) xs)
                , test "true" <| \() -> Expect.equal (True) (any (\_ z -> z >= n) zs)
                ]
            , describe "sort"
                [ test "sorted" <| \() -> Expect.equal (xs) (sort xs)
                , test "unsorted" <| \() -> Expect.equal (xsOpp) (sort xsNeg)
                ]
            , describe "sortBy"
                [ test "sorted" <| \() -> Expect.equal (xsNeg) (sortBy negate xsNeg)
                , test "unsorted" <| \() -> Expect.equal (xsNeg) (sortBy negate xsOpp)
                ]
            , describe "sortWith"
                [ test "sorted" <| \() -> Expect.equal (xsNeg) (sortWith (flip compare) xsNeg)
                , test "unsorted" <| \() -> Expect.equal (xsNeg) (sortWith (flip compare) xsOpp)
                ]
            ]
