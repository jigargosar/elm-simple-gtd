module TrieModel exposing
  ( Trie(..)
  , empty
  , add
  , remove
  , has
  , get
  , getNode
  , valueCount
  , expand
  , getValues
  )

{-| A Trie data structure.

A trie is an ordered tree data structure that is used to store a dynamic
set or associative array where the keys are usually strings.

In this implementation they key is a String.

In this implementation unique reference stored in the value
dictionary for a given key is a String.

## Data Model
@docs Trie

## Create
@docs empty

## Modify
@docs add
@docs remove

## Query
@docs has
@docs get
@docs getNode
@docs valueCount
@docs expand

## Get data values from node
@docs getValues

Copyright (c) 2016 Robin Luiten
-}

import Dict exposing (Dict)
import List
import Maybe
import String


-- import TrieModel

{-| Trie data model. -}
type Trie a
  = EmptyTrie
  | ValNode (Dict String a)
  | TrieNode (Dict String (Trie a))
  | ValTrieNode (Dict String a, Dict String (Trie a))


{-| An empty Trie -}
empty : Trie a
empty = EmptyTrie


{-| Returns True if Trie is empty -}
isEmpty : Trie a -> Bool
isEmpty trie =
  trie == empty


{-| Add reference and values with key to Trie.
-}
add : (String, a) -> String -> Trie a -> Trie a
add refValues key trie =
  addByStr refValues (toListString key) trie


{- break string up into list of single Char strings -}
toListString : String -> List String
toListString str =
    List.map
      (\c -> String.fromChar c)
      (String.toList str)


{-| see add
-}
addByStr : (String, a) -> List String -> Trie a -> Trie a
addByStr (ref, value) key trie =
  case key of
    [] ->
      case trie of
        EmptyTrie ->
          ValNode (Dict.singleton ref value)

        ValNode refValues ->
          ValNode (Dict.insert ref value  refValues)

        TrieNode trieDict ->
          ValTrieNode (Dict.singleton ref value, trieDict)

        ValTrieNode (refValues, trieDict) ->
          ValTrieNode (Dict.insert ref value refValues, trieDict)

    keyHead :: keyTail ->
      let
        lazyNewTrieDict =
            (\_ ->
              addByStr (ref, value) keyTail EmptyTrie
                |> Dict.singleton keyHead
            )

        updateTrieDict trieDict =
          let
            updatedSubTrie =
              Dict.get keyHead trieDict
                |> Maybe.withDefault EmptyTrie
                |> addByStr (ref, value) keyTail
          in
            Dict.insert keyHead updatedSubTrie trieDict
      in
        case trie of
          EmptyTrie ->
            TrieNode (lazyNewTrieDict ())

          ValNode refValues ->
            ValTrieNode (refValues, lazyNewTrieDict ())

          TrieNode trieDict ->
            TrieNode (updateTrieDict trieDict)

          ValTrieNode (refValues, trieDict) ->
            ValTrieNode (refValues, updateTrieDict trieDict)


{-| Remove values for key and reference from Trie.

This removes the reference from the correct values list.
If the key does not exist nothing changes.
If the ref is not found in the values for the key nothing changes.

An example but does not do anything.
```
updatedTrie = Trie.remove "for" "refid125" Trie.empty
```


Add something then remove it.
```
trie1 = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty

trie2 = Trie.remove "someword" "refid123" Trie.trie1
```

-}
remove : String -> String -> Trie a -> Trie a
remove key ref trie =
  removeByStr (toListString key) ref trie


{-| see remove
-}
removeByStr : List String -> String -> Trie a -> Trie a
removeByStr key ref trie =
  case key of
    [] ->
      case trie of
        EmptyTrie ->
          trie

        ValNode refValues ->
          ValNode (Dict.remove ref refValues)

        TrieNode trieDict ->
          trie

        ValTrieNode (refValues, trieDict) ->
          ValTrieNode (Dict.remove ref refValues, trieDict)

    keyHead :: keyTail ->
      let
        removeTrieDict trieDict =
            case (Dict.get keyHead trieDict) of
              Nothing ->
                trieDict

              Just subTrie ->
                Dict.insert keyHead (removeByStr keyTail ref subTrie) trieDict
      in
        case trie of
          EmptyTrie ->
            trie

          ValNode refValues ->
            trie

          TrieNode trieDict ->
            TrieNode (removeTrieDict trieDict)

          ValTrieNode (refValues, trieDict) ->
            ValTrieNode (refValues, removeTrieDict trieDict)


{-| Return Trie node if found.
-}
getNode : String -> Trie a -> Maybe (Trie a)
getNode key trie =
  getNodeByStr (toListString key) trie


{-| see getNode
-}
getNodeByStr : List String -> Trie a -> Maybe (Trie a)
getNodeByStr key trie =
  if List.isEmpty key then
    Nothing
  else
    getNodeCore key trie


getNodeCore : List String -> Trie a -> Maybe (Trie a)
getNodeCore key trie =
  case key of
    [] ->
      Just trie

    keyHead :: keyTail ->
      let
        getTrie trieDict =
          (Dict.get keyHead trieDict) |>
             Maybe.andThen (getNodeCore keyTail)
      in
        case trie of
          EmptyTrie ->
            Nothing

          ValNode _ ->
            Nothing

          TrieNode trieDict ->
            getTrie trieDict

          ValTrieNode (_, trieDict) ->
            getTrie trieDict


{-| Checks whether key is contained within a Trie.
-}
has : String -> Trie a -> Bool
has key trie =
  hasByStr (toListString key) trie


{-| see has
-}
hasByStr : List String -> Trie a -> Bool
hasByStr key trie =
  (getNodeByStr key trie)
    |> Maybe.andThen getValues
    |> Maybe.withDefault Dict.empty
    |> not << Dict.isEmpty


{-| Return values for a key if found.
-}
get : String -> Trie a -> Maybe (Dict String a)
get key trie =
  getByStr (toListString key) trie


{-| see get
-}
getByStr : List String -> Trie a -> Maybe (Dict String a)
getByStr key trie =
  (getNodeByStr key trie)
    |> Maybe.andThen getValues


{-| Return the values stored if there are any
-}
getValues : Trie a -> Maybe (Dict String a)
getValues trie =
  case trie of
    EmptyTrie ->
      Nothing

    ValNode refValues ->
      Just refValues

    TrieNode _ ->
      Nothing

    ValTrieNode (refValues, _) ->
      Just refValues


{-| Return number of values stored at Trie location.
-}
valueCount : String -> Trie a -> Int
valueCount key trie =
  Dict.size (Maybe.withDefault Dict.empty (get key trie))


{-| see valueCount
-}
valueCountByStr : List String -> Trie a -> Int
valueCountByStr key trie =
  Maybe.withDefault Dict.empty (getByStr key trie)
    |> Dict.size


{-| Find all the possible suffixes of the passed key using keys
currently in the store.
-}
expand : String -> Trie a-> List String
expand key trie =
  expandByStr (toListString key) trie


{-| see expand
-}
expandByStr : List String -> Trie a -> List String
expandByStr key trie  =
  case getNodeByStr key trie of
    Nothing ->
      []

    Just keyTrie ->
      expandCore key keyTrie []


expandCore : List String -> Trie a -> List String -> List String
expandCore key trie keyList =
  let
    addRefKey refValues =
      if not (Dict.isEmpty refValues) then
        -- (String.fromList key) :: keyList
        (String.concat key) :: keyList
      else
        keyList
    expandSub char trie foldList =
      expandCore (key ++ [ char ]) trie foldList
  in
    case trie of
      EmptyTrie ->
        keyList

      ValNode refValues ->
        addRefKey refValues

      TrieNode trieDict ->
        Dict.foldr expandSub keyList trieDict

      ValTrieNode (refValues, trieDict) ->
        let
          dirtyList = addRefKey refValues
        in
          Dict.foldr expandSub dirtyList trieDict
