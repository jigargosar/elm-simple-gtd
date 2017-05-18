module Trie exposing
  ( Trie
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
import Maybe exposing (withDefault, andThen)
import String


import TrieModel


{-| Trie data model. -}
type alias Trie a = TrieModel.Trie a

{-| An empty Trie -}
empty : Trie a
empty = TrieModel.empty


{-| Returns True if Trie is empty -}
isEmpty : Trie a -> Bool
isEmpty trie =
    trie == empty


{-| Add reference and values with key to Trie.

```
updatedTrie = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty
```
-}
add : (String, a) -> String -> Trie a -> Trie a
add = TrieModel.add


{- break string up into list of single Char strings -}
toListString : String -> List String
toListString str =
    List.map
      (\c -> String.fromChar c)
      (String.toList str)


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
remove = TrieModel.remove


{-| Return Trie node if found.

This will return Nothing.
```
maybeNode = Trie.getNode "for" Trie.empty
```

This will the node containing the values for the word "someword".
It will contains "refid123" in the dictionary point at  ("ValueStored", 42.34).
```
trie1 = Trie.add ("refid123", ("ValueStored", 42.34)) "someword" Trie.empty

maybeNode = Trie.getNode "someword" trie1
```

-}
getNode : String -> Trie a -> Maybe (Trie a)
getNode = TrieModel.getNode


{-| Checks whether key is contained within a Trie.

A key must have values for it be considered present in Trie.
-}
has : String -> Trie a -> Bool
has = TrieModel.has


{-| Return values for a key if found.
-}
get : String -> Trie a -> Maybe (Dict String a)
get = TrieModel.get


{-| Return the values stored if there are any
-}
getValues : Trie a -> Maybe (Dict String a)
getValues = TrieModel.getValues


{-| Return number of values stored at Trie location.
-}
valueCount : String -> Trie a -> Int
valueCount = TrieModel.valueCount


{-| Find all the possible suffixes of the passed key using keys
currently in the store.

This returns a List of all keys from starting key down.
The definition of a key that exists is one that has documents defined for it.

Given this setup
```
    trie1 = Trie.add ("refid121", 1) "ab" Trie.empty
    trie2 = Trie.add ("refid122", 2) "ac" trie1
    trie3 = Trie.add ("refid123", 3) "acd" trie2
```

This
```
    Trie.expand "a" trie3
```
Returns
```
["ab","acd","ac"]
```


This
```
    Trie.expand "ac" trie3
```
Returns
```
["acd","ac"]
```

-}
expand : String -> Trie a-> List String
expand = TrieModel.expand
