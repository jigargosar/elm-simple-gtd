port module Main exposing (..)

import Test exposing (..)
import Test.Runner.Node exposing (run, TestProgram)
import Json.Encode exposing (Value)

import StemmerTests
import StemmerTestsFullPorter


main : TestProgram
main =
    run emit <|
      describe "Stemmer and StemmerFullPorter tests"
        [ StemmerTests.tests
        , StemmerTestsFullPorter.tests
        ]


port emit : ( String, Value ) -> Cmd msg
