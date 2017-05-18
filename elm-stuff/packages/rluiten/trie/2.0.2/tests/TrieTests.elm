module TrieTests exposing (..)

import Dict
import Expect
import Test exposing (..)
import Set

import Trie
import TrieModel  exposing (Trie (EmptyTrie))


tests : Test
tests =
  describe "DocTrie tests"
    [ addTest1 ()
    , addTest2 ()
    , hasTest1 ()
    , hasTest2 ()
    , hasTest3 ()
    , getTest1 ()
    , getTest2 ()
    , expandTest1 ()
    , removeTest1 ()
    ]


addTest1 : () -> Test
addTest1 _ =
  test "add test 1" <|
    \() -> Expect.equal Trie.empty EmptyTrie


type alias MyDoc =
  { cid : String
  , title : String
  , author : String
  , body : String
  }


doc1 : MyDoc
doc1 =
  { cid = "3"
  , title = "t1"
  , author = "a1"
  , body = "b1"
  }


addTest2 : () -> Test
addTest2 _ =
  let
    trieU1 = Trie.add ("refid123", doc1) "ab" Trie.empty
    -- _ = Debug.log("addtest2 1") (trieU1)
    trieU2 = Trie.add ("refid123", doc1) "ac" trieU1
    -- _ = Debug.log("addtest2 2") (trieU2)
  in
    describe "add test 2"
      [ test "a" <|
          \() -> Expect.notEqual EmptyTrie trieU1
      , test "b" <|
          \() -> Expect.notEqual EmptyTrie trieU2
      , test "c" <|
          \() -> Expect.notEqual trieU1 trieU2
      ]


hasTest1 : () -> Test
hasTest1 _ =
  test "EmptyTrie does not have \"ab\"" <|
    \() ->
      (Trie.has "ab" EmptyTrie)
        |> Expect.false "EmptyTree should not contain any token."


hasTest2 : () ->  Test
hasTest2 _ =
  let
    trieU1 = Trie.add ("refid123", doc1) "ab" Trie.empty
  in
    test "Created trie has \"ab\"" <|
    \() ->
      (Trie.has "ab" trieU1)
        |> Expect.true "Trie created with token should contain it"


hasTest3 : () -> Test
hasTest3 _ =
  test "EmptyTrie does not have \"\"" <|
    \() ->
      (Trie.has "" EmptyTrie)
        |> Expect.false "EmptyTree does not even contain empty string."



getTest1 : () -> Test
getTest1 _ =
  let
    trie1 = Trie.getNode "ab" EmptyTrie
    trie2 = Trie.getNode "" EmptyTrie
  in
    describe "get test 1"
      [ test "get \"ab\" from EmptyTree is Nothing" <|
          \() -> Expect.equal trie1 Nothing
      , test "get \"\" from EmptyTree is Nothing" <|
          \() -> Expect.equal trie2 Nothing
      ]


getTest2 : () -> Test
getTest2 _ =
  let
    trieU1 = Trie.add ("refid123", doc1) "ab" Trie.empty
    trie1 = Trie.getNode "a" trieU1
    trie2 = Trie.getNode "ab" trieU1
    trie3 = Trie.getNode "abc" trieU1
  in
    describe "get test 2"
      [ test "get \"a\" from trieU1 is not Nothing" <|
          \() -> Expect.notEqual trie1 Nothing
      , test "get \"ab\" from trieU1 is not Nothing" <|
          \() -> Expect.notEqual trie2 Nothing
      , test "get \"abc\" from trieU1 is Nothing" <|
          \() -> Expect.equal trie3 Nothing
      ]


expandTest1 : () -> Test
expandTest1 _ =
  let
      trieU1 = Trie.add ("refid121", 1) "ab" Trie.empty
      trieU2 = Trie.add ("refid122", 2) "ac" trieU1
      trieU3 = Trie.add ("refid123", 3) "acd" trieU2
      trieU4 = Trie.add ("refid124", 4) "for" trieU3
      trieU5 = Trie.add ("refid125", 5) "forward" trieU4
      tokens1 = Trie.expand "a" trieU5
      tokens2 = Trie.expand "ac" trieU5
      tokens3 = Trie.expand "" trieU5
      tokens4 = Trie.expand "b" trieU5
      tokens5 = Trie.expand "f" trieU5
      tokens6 = Trie.expand "for" trieU5
      -- _ = Debug.log("expandTest1") (tokens1,tokens2,tokens3,tokens4,tokens5,tokens6)
      setBounce list = Set.toList (Set.fromList list)
  in
    describe "expand test 1"
      [ test "expand \"a\"" <|
          \() -> (Expect.equal ["ab","acd","ac"] tokens1)
      , test "expand \"ac\"" <|
          \() -> (Expect.equal ["acd","ac"] tokens2)
      , test "expand \"\"" <|
          \() -> (Expect.equal [] tokens3)
      , test "expand \"b\"" <|
          \() -> (Expect.equal [] tokens4)
      , test "expand \"f\"" <|
          \() -> (Expect.equal (setBounce ["for","forward"]) (setBounce tokens5))
      , test "expand \"for\"" <|
          \() -> (Expect.equal (setBounce ["for","forward"]) (setBounce tokens5))
      ]


removeTest1 : () -> Test
removeTest1 _ =
  let
      trieU1 = Trie.add ("refid121", 1) "ab" Trie.empty
      trieU2 = Trie.add ("refid122", 2) "ac" trieU1
      trieU3 = Trie.add ("refid123", 3) "acd" trieU2
      trieU4 = Trie.add ("refid124", 4) "for" trieU3
      trieU5 = Trie.add ("refid125", 5) "forward" trieU4

      -- _ = Debug.log "removeTest1 a" (trieU5)
      -- _ = Debug.log("removeTest1 b get") (Trie.get "for" trieU5)
      -- _ = Debug.log("removeTest1 b1 rem") (Trie.remove "for" "refid125" trieU5)
      -- _ = Debug.log("removeTest1 b2 rem") (Trie.remove "for" "refid124" trieU5)
      -- _ = Debug.log("removeTest1 b3 rem") (Trie.remove "forward" "refid125" trieU5)
      -- _ = Debug.log("removeTest1 c has") (Trie.has "for" trieU5)
      -- _ = Debug.log("removeTest1 c1 has") (Trie.has "for" (Trie.remove "for" "refid125" trieU5))
      -- _ = Debug.log("removeTest1 c2 has") (Trie.has "for" (Trie.remove "for" "refid124" trieU5))
      -- _ = Debug.log("removeTest1 d rem") (Trie.remove "for" "refid124" trieU5)
  in
    describe "remove test 1"
      [ test "remove token but doc reference wrong, so does not change trie" <|
          \() ->
            (Trie.has "for" (Trie.remove "for" "refid125" trieU5))
              |> Expect.true "Removing token with non wrong document reference does not remove it."
      , test "remove token with right doc reference" <|
          \() ->
            (Trie.has "for" (Trie.remove "for" "refid124" trieU5))
              |> Expect.false "Removing token with correct doc reference does remove it."
      , test "remove token with right doc reference" <|
          \() ->
            (Trie.has "forward" (Trie.remove "forward" "refid125" trieU5))
              |> Expect.false "Removing token with correct doc reference does remove it."
      ]
