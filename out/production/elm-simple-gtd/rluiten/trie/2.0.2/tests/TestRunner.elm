module TestRunner exposing (..)

import String
import ElmTest exposing (..)

import TrieTests
import TrieCodecTests


main =
  runSuite
    ( suite "Element Test Runner Tests"
      [ TrieTests.tests
      , TrieCodecTests.tests
      ]
    )
