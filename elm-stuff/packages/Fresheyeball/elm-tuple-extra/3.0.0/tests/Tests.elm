module Tests exposing (..)

import Test exposing (describe, Test)
import Test.Tuple2
import Test.Tuple3
import Test.Tuple4


all : Test
all =
    describe "elm-tuple-extra Suite"
        [ Test.Tuple2.tests
        , Test.Tuple3.tests
        , Test.Tuple4.tests
        ]
