module EveryDictListTests exposing (..)

import Test exposing (Test, describe, test, fuzz, fuzz2)
import Fuzz exposing (Fuzzer, intRange)
import Expect
import Json.Encode exposing (Value)
import Dict
import EveryDictList exposing (..)
import Set


type Action
    = Run
    | Hide
    | StandStill


actionDict : EveryDictList Action String
actionDict =
    EveryDictList.fromList
        [ ( Run, "Run away!" )
        , ( Hide, "Coward!" )
        , ( StandStill, "Err..." )
        ]


basicTest : Test
basicTest =
    test "get" <|
        \_ ->
            EveryDictList.get Run actionDict
                |> Expect.equal (Just "Run away!")
