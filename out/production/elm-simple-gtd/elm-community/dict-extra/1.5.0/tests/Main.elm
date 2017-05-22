port module Main exposing (main, emit)

import Test.Runner.Node exposing (run, TestProgram)
import Test exposing (Test, describe, test)
import Expect
import Json.Encode exposing (Value)
import Dict exposing (Dict)
import Dict.Extra exposing (..)
import Set


main : TestProgram
main =
    run emit tests


port emit : ( String, Value ) -> Cmd msg


tests : Test
tests =
    describe "Dict tests"
        [ groupByTests
        , fromListByTests
        , removeWhenTests
        , removeManyTests
        , keepOnlyTests
        , mapKeysTests
        , invertTests
        , findTests
        ]



-- groupBy


groupByTests : Test
groupByTests =
    describe "groupBy"
        [ test "example" <|
            \() ->
                Dict.toList (groupBy .id [ mary, jack, jill ])
                    |> Expect.equal [ ( 1, [ mary, jill ] ), ( 2, [ jack ] ) ]
        ]


type alias GroupByData =
    { id : Int
    , name : String
    }


mary : GroupByData
mary =
    GroupByData 1 "Mary"


jack : GroupByData
jack =
    GroupByData 2 "Jack"


jill : GroupByData
jill =
    GroupByData 1 "Jill"



-- fromListBy


fromListByTests : Test
fromListByTests =
    describe "fromListBy"
        [ test "example" <|
            \() ->
                fromListBy .id [ jack, jill ]
                    |> Expect.equal (Dict.fromList [ ( 2, jack ), ( 1, jill ) ])
        , test "replacement" <|
            \() ->
                fromListBy .id [ jack, jill, mary ]
                    |> Expect.equal (Dict.fromList [ ( 2, jack ), ( 1, mary ) ])
        ]



-- removeWhen


removeWhenTests : Test
removeWhenTests =
    describe "removeWhen"
        [ test "example" <|
            \() ->
                removeWhen (\_ v -> v == 1) (Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ])
                    |> Expect.equal (Dict.fromList [ ( "Jack", 2 ) ])
        ]



-- removeMany


removeManyTests : Test
removeManyTests =
    describe "removeMany"
        [ test "example" <|
            \() ->
                removeMany (Set.fromList [ "Mary", "Jill" ]) (Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ])
                    |> Expect.equal (Dict.fromList [ ( "Jack", 2 ) ])
        ]



-- keepOnly


keepOnlyTests : Test
keepOnlyTests =
    describe "keepOnly"
        [ test "example" <|
            \() ->
                keepOnly (Set.fromList [ "Jack", "Jill" ]) (Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ])
                    |> Expect.equal (Dict.fromList [ ( "Jack", 2 ), ( "Jill", 1 ) ])
        ]



-- mapKeys


mapKeysTests : Test
mapKeysTests =
    describe "mapKeys"
        [ test "example" <|
            \() ->
                mapKeys ((+) 1) (Dict.fromList [ ( 1, "Jack" ), ( 2, "Jill" ) ])
                    |> Expect.equal (Dict.fromList [ ( 2, "Jack" ), ( 3, "Jill" ) ])
        ]



-- filterMap


filterMapTests : Test
filterMapTests =
    describe "filterMap"
        [ test "example" <|
            \() ->
                let
                    isTeen : Int -> String -> Maybe String
                    isTeen n a =
                        if 13 <= n && n <= 19 then
                            Just <| String.toUpper a
                        else
                            Nothing

                    inputDict : Dict Int String
                    inputDict =
                        Dict.fromList
                            [ ( 5, "Jack" )
                            , ( 15, "Jill" )
                            , ( 20, "Jones" )
                            ]
                in
                    filterMap isTeen inputDict
                        |> Expect.equalDicts (Dict.singleton 15 "JILL")
        ]



-- Invert


invertTests : Test
invertTests =
    describe "invert"
        [ test "example" <|
            \() ->
                invert (Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ) ])
                    |> Expect.equalDicts (Dict.fromList [ ( "Jack", 5 ), ( "Jill", 10 ) ])
        ]



-- Find


findTests : Test
findTests =
    describe "find"
        [ test "find JoMomma" <|
            \() ->
                find (\key value -> value == "JoMomma") (Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ), ( 77, "JoMomma" ) ])
                    |> Expect.equal (Just ( 77, "JoMomma" ))
        , test "can't find JoBuddy" <|
            \() ->
                find (\key value -> value == "JoBuddy") (Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ), ( 77, "JoMomma" ) ])
                    |> Expect.equal Nothing
        , test "find the first Jack" <|
            \() ->
                find (\key value -> value == "Jack") (Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ), ( 0, "Jack" ) ])
                    |> Expect.equal (Just ( 0, "Jack" ))
        ]
