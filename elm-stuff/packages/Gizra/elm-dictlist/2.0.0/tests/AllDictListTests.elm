module AllDictListTests exposing (..)

import Test exposing (Test, describe, test, fuzz, fuzz2)
import Fuzz exposing (Fuzzer, intRange)
import Expect
import Json.Encode exposing (Value)
import Dict
import AllDictList exposing (..)
import Set


type Action
    = Run
    | Hide
    | StandStill


ord : Action -> Int
ord action =
    case action of
        Run ->
            2

        Hide ->
            1

        StandStill ->
            0


actionDict : AllDictList Action String Int
actionDict =
    AllDictList.fromList ord
        [ ( Run, "Run away!" )
        , ( Hide, "Coward!" )
        , ( StandStill, "Err..." )
        ]


basicTest : Test
basicTest =
    test "get" <|
        \_ ->
            AllDictList.get Run actionDict
                |> Expect.equal (Just "Run away!")
