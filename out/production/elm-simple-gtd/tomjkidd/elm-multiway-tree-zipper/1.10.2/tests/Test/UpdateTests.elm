module Test.UpdateTests exposing (..)

import Legacy.ElmTest as ElmTest exposing (..)
import MultiwayTree exposing (Tree(..))
import MultiwayTreeZipper exposing (..)
import Test.SampleData
    exposing
        ( noChildTree
        , singleChildTree
        , multiChildTree
        , deepTree
        , interestingTree
        , simpleForest
        , noChildRecord
        )
import Test.Utils exposing (..)


tests : Test
tests =
    suite "Update"
        [ test "Update datum (simple)" <|
            assertEqual
                (Just ( (Tree "ax" []), [] ))
                (Just ( noChildTree, [] )
                    &> updateDatum (\a -> a ++ "x")
                )
        , test "Update datum (record)" <|
            assertEqual
                (Just ( (Tree { selected = True, expanded = False } []), [] ))
                (Just ( noChildRecord, [] )
                    &> updateDatum (\rec -> { rec | selected = True })
                )
        , test "Replace datum (simple)" <|
            assertEqual
                (Just ( (Tree "x" []), [] ))
                (Just ( noChildTree, [] )
                    &> replaceDatum "x"
                )
        , test "Replace datum (record)" <|
            assertEqual
                (Just ( (Tree { selected = True, expanded = True } []), [] ))
                (Just ( noChildRecord, [] )
                    &> replaceDatum { selected = True, expanded = True }
                )
        , test "Replace children (replace with empty)" <|
            assertEqual
                (Just ( noChildTree, [] ))
                (Just ( singleChildTree, [] )
                    &> updateChildren []
                )
        , test "Replace children (replace with specific)" <|
            assertEqual
                (Just ( Tree "a" simpleForest, [] ))
                (Just ( interestingTree, [] )
                    &> updateChildren simpleForest
                )
        ]
