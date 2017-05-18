port module Main exposing (..)

import Json.Encode exposing (Value)
import Test exposing (..)
import Test.Runner.Node exposing (run, TestProgram)

import TrieTests
import TrieCodecTests


main : TestProgram
main =
    run emit <|
      describe "TrieTests, TrieCodecTests"
        [ TrieTests.tests
        , TrieCodecTests.tests
        ]


port emit : ( String, Value ) -> Cmd msg
