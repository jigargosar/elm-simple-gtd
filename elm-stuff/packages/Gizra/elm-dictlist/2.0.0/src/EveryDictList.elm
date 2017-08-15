module EveryDictList
    exposing
        ( EveryDictList
          -- originally from `EveryDict`
        , empty
        , eq
        , singleton
        , insert
        , update
        , isEmpty
        , get
        , remove
        , member
        , size
        , filter
        , partition
        , foldl
        , foldr
        , map
        , union
        , intersect
        , diff
        , merge
        , keys
        , values
        , toList
        , fromList
          -- core `List`
        , cons
        , head
        , tail
        , indexedMap
        , filterMap
        , length
        , reverse
        , all
        , any
        , append
        , concat
        , sum
        , product
        , maximum
        , minimum
        , take
        , drop
        , sort
        , sortBy
        , sortWith
          -- list-oriented
        , getAt
        , getKeyAt
        , indexOfKey
        , insertAfter
        , insertBefore
        , next
        , previous
        , relativePosition
        , insertRelativeTo
        , atRelativePosition
          -- JSON
        , decodeObject
        , decodeWithKeys
        , decodeKeysAndValues
        , decodeArray
        , decodeArray2
          -- Conversion
        , toDict
        , toAllDictList
        , fromDict
        , fromAllDictList
          -- Dict.Extra
        , groupBy
        , fromListBy
        , removeWhen
        , removeMany
        , keepOnly
        , mapKeys
        )

{-| Have you ever wanted an `EveryDict`, but you need to maintain an arbitrary
ordering of keys? Or, a `List`, but you want to efficiently lookup values
by a key? With `EveryDictList`, now you can!

`EveryDictList` implements the full API for `EveryDict` (and should be a drop-in
replacement for it). However, instead of ordering things from lowest
key to highest key, it allows for an arbitrary ordering.

We also implement most of the API for `List`. However, the API is not
identical, since we need to account for both keys and values.

An alternative would be to maintain your own "association list" -- that is,
a `List (k, v)` instead of an `EveryDictList k v`. You can move back and forth
between an association list and a dictionary via `toList` and `fromList`.

# EveryDictList

@docs EveryDictList, eq

# Build

Functions which create or update a dictionary.

@docs empty, singleton, insert, update, remove
@docs take, drop
@docs removeWhen, removeMany, keepOnly
@docs cons, insertAfter, insertBefore, insertRelativeTo

# Combine

Functions which combine two dictionaries.

@docs append, concat
@docs union, intersect, diff, merge

# Query

Functions which get information about a dictionary.

@docs isEmpty, size, length
@docs all, any
@docs sum, product, maximum, minimum

# Elements

Functions that pick out an element of a dictionary,
or provide information about an element.

@docs member, get, getAt, getKeyAt
@docs indexOfKey, relativePosition, atRelativePosition
@docs head, tail
@docs next, previous

# Transform

Functions that transform a dictionary

@docs map, mapKeys, foldl, foldr, filter, partition
@docs indexedMap, filterMap, reverse
@docs sort, sortBy, sortWith

# Convert

Functions that convert between a dictionary and a related type.

@docs keys, values, toList, fromList, fromListBy, groupBy
@docs toDict, fromDict
@docs toAllDictList, fromAllDictList

# JSON

Functions that help to decode a dictionary.

@docs decodeObject, decodeArray, decodeArray2, decodeWithKeys, decodeKeysAndValues

-}

import AllDictList exposing (AllDictList, RelativePosition)
import Dict exposing (Dict)
import Json.Decode exposing (Decoder, keyValuePairs, value, decodeValue)
import Json.Decode as Json18
import List.Extra
import Maybe as Maybe18
import Set exposing (Set)
import Tuple exposing (first, second)


{-| A `Dict` that maintains an arbitrary ordering of keys (rather than sorting
them, as a normal `Dict` does. Or, a `List` that permits efficient lookup of
values by a key. You can look at it either way.
-}
type alias EveryDictList k v =
    AllDictList k v String



-------
-- JSON
-------


{-| Turn any object into a dictionary of key-value pairs, including inherited
enumerable properties. Fails if _any_ value can't be decoded with the given
decoder.

Unfortunately, it is not possible to preserve the apparent order of the keys in
the JSON, because the keys in Javascript objects are fundamentally un-ordered.
Thus, you will typically need to have at least your keys in an array in the JSON,
and use `decodeWithKeys`, `decodeArray` or `decodeArray2`.
-}
decodeObject : Decoder a -> Decoder (EveryDictList String a)
decodeObject =
    AllDictList.decodeObject


{-| This function produces a decoder you can use if you can decode a list of your keys,
and given a key, you can produce a decoder for the corresponding value. The
order within the dictionary will be the order of your list of keys.
-}
decodeWithKeys : List k -> (k -> Decoder v) -> Decoder (EveryDictList k v)
decodeWithKeys =
    AllDictList.decodeWithKeys toString


{-| Like `decodeWithKeys`, but you supply a decoder for the keys, rather than the keys themselves.

Note that the starting point for all decoders will be the same place, so you need to construct your
decoders in a way that makes that work.
-}
decodeKeysAndValues : Decoder (List k) -> (k -> Decoder v) -> Decoder (EveryDictList k v)
decodeKeysAndValues =
    AllDictList.decodeKeysAndValues toString


{-| Given a decoder for the value, and a way of turning the value into a key,
decode an array of values into a dictionary. The order within the dictionary
will be the order of the JSON array.
-}
decodeArray : (v -> k) -> Decoder v -> Decoder (EveryDictList k v)
decodeArray =
    AllDictList.decodeArray toString


{-| Decodes a JSON array into the EveryDictList. You supply two decoders. Given an element
of your JSON array, the first decoder should decode the key, and the second decoder
should decode the value.
-}
decodeArray2 : Decoder k -> Decoder v -> Decoder (EveryDictList k v)
decodeArray2 =
    AllDictList.decodeArray2 toString



----------------------
-- From `List` in core
----------------------


{-| Insert a key-value pair at the front. Moves the key to the front if
    it already exists.
-}
cons : k -> v -> EveryDictList k v -> EveryDictList k v
cons =
    AllDictList.cons


{-| Gets the first key with its value.
-}
head : EveryDictList k v -> Maybe ( k, v )
head =
    AllDictList.head


{-| Extract the rest of the dictionary, without the first key/value pair.
-}
tail : EveryDictList k v -> Maybe (EveryDictList k v)
tail =
    AllDictList.tail


{-| Like `map` but the function is also given the index of each
element (starting at zero).
-}
indexedMap : (Int -> k -> a -> b) -> EveryDictList k a -> EveryDictList k b
indexedMap =
    AllDictList.indexedMap


{-| Apply a function that may succeed to all key-value pairs, but only keep
the successes.
-}
filterMap : (k -> a -> Maybe b) -> EveryDictList k a -> EveryDictList k b
filterMap =
    AllDictList.filterMap


{-| The number of key-value pairs in the dictionary.
-}
length : EveryDictList k v -> Int
length =
    AllDictList.length


{-| Reverse the order of the key-value pairs.
-}
reverse : EveryDictList k v -> EveryDictList k v
reverse =
    AllDictList.reverse


{-| Determine if all elements satisfy the predicate.
-}
all : (k -> v -> Bool) -> EveryDictList k v -> Bool
all =
    AllDictList.all


{-| Determine if any elements satisfy the predicate.
-}
any : (k -> v -> Bool) -> EveryDictList k v -> Bool
any =
    AllDictList.any


{-| Put two dictionaries together.

If keys collide, preference is given to the value from the second dictionary.
Also, the order of the keys in the second dictionary will be preserved at the
end of the result.

So, you could think of `append` as biased towards the second argument. The end
of the result should be equal to the second argument, both in value and key-order.
The front of the result will then be whatever is left from the first argument --
that is, those keys (and their values) that were not in the second argument.

For a similar function that is biased towards the first argument, see `union`.
-}
append : EveryDictList k v -> EveryDictList k v -> EveryDictList k v
append =
    AllDictList.append


{-| Concatenate a bunch of dictionaries into a single dictionary.

Works from left to right, applying `append` as it goes.
-}
concat : List (EveryDictList k v) -> EveryDictList k v
concat =
    AllDictList.concat toString


{-| Get the sum of the values.
-}
sum : EveryDictList k number -> number
sum =
    AllDictList.sum


{-| Get the product of the values.
-}
product : EveryDictList k number -> number
product =
    AllDictList.product


{-| Find the maximum value. Returns `Nothing` if empty.
-}
maximum : EveryDictList k comparable -> Maybe comparable
maximum =
    AllDictList.maximum


{-| Find the minimum value. Returns `Nothing` if empty.
-}
minimum : EveryDictList k comparable -> Maybe comparable
minimum =
    AllDictList.minimum


{-| Take the first *n* values.
-}
take : Int -> EveryDictList k v -> EveryDictList k v
take =
    AllDictList.take


{-| Drop the first *n* values.
-}
drop : Int -> EveryDictList k v -> EveryDictList k v
drop =
    AllDictList.drop


{-| Sort values from lowest to highest
-}
sort : EveryDictList k comparable -> EveryDictList k comparable
sort =
    AllDictList.sort


{-| Sort values by a derived property.
-}
sortBy : (v -> comparable) -> EveryDictList k v -> EveryDictList k v
sortBy =
    AllDictList.sortBy


{-| Sort values with a custom comparison function.
-}
sortWith : (v -> v -> Order) -> EveryDictList k v -> EveryDictList k v
sortWith =
    AllDictList.sortWith



----------------
-- List-oriented
----------------


{-| Given a key, what index does that key occupy (0-based) in the
order maintained by the dictionary?
-}
indexOfKey : k -> EveryDictList k v -> Maybe Int
indexOfKey =
    AllDictList.indexOfKey


{-| Given a key, get the key and value at the next position.
-}
next : k -> EveryDictList k v -> Maybe ( k, v )
next =
    AllDictList.next


{-| Given a key, get the key and value at the previous position.
-}
previous : k -> EveryDictList k v -> Maybe ( k, v )
previous =
    AllDictList.previous


{-| Gets the key at the specified index (0-based).
-}
getKeyAt : Int -> EveryDictList k v -> Maybe k
getKeyAt =
    AllDictList.getKeyAt


{-| Gets the key and value at the specified index (0-based).
-}
getAt : Int -> EveryDictList k v -> Maybe ( k, v )
getAt =
    AllDictList.getAt


{-| Insert a key-value pair into a dictionary, replacing an existing value if
the keys collide. The first parameter represents an existing key, while the
second parameter is the new key. The new key and value will be inserted after
the existing key (even if the new key already exists). If the existing key
cannot be found, the new key/value pair will be inserted at the end.
-}
insertAfter : k -> k -> v -> EveryDictList k v -> EveryDictList k v
insertAfter =
    AllDictList.insertAfter


{-| Insert a key-value pair into a dictionary, replacing an existing value if
the keys collide. The first parameter represents an existing key, while the
second parameter is the new key. The new key and value will be inserted before
the existing key (even if the new key already exists). If the existing key
cannot be found, the new key/value pair will be inserted at the beginning.
-}
insertBefore : k -> k -> v -> EveryDictList k v -> EveryDictList k v
insertBefore =
    AllDictList.insertBefore


{-| Get the position of a key relative to the previous key (or next, if the
first key). Returns `Nothing` if the key was not found.
-}
relativePosition : k -> EveryDictList k v -> Maybe (RelativePosition k)
relativePosition =
    AllDictList.relativePosition


{-| Gets the key-value pair currently at the indicated relative position.
-}
atRelativePosition : RelativePosition k -> EveryDictList k v -> Maybe ( k, v )
atRelativePosition =
    AllDictList.atRelativePosition


{-| Insert a key-value pair into a dictionary, replacing an existing value if
the keys collide. The first parameter represents an existing key, while the
second parameter is the new key. The new key and value will be inserted
relative to the existing key (even if the new key already exists). If the
existing key cannot be found, the new key/value pair will be inserted at the
beginning (if the new key was to be before the existing key) or the end (if the
new key was to be after).
-}
insertRelativeTo : RelativePosition k -> k -> v -> EveryDictList k v -> EveryDictList k v
insertRelativeTo =
    AllDictList.insertRelativeTo



-------------------
-- From `EveryDict`
-------------------


{-| Create an empty dictionary.
-}
empty : EveryDictList k v
empty =
    AllDictList.empty toString


{-| Element equality.
-}
eq : EveryDictList k v -> EveryDictList k v -> Bool
eq =
    AllDictList.eq


{-| Get the value associated with a key. If the key is not found, return
`Nothing`.
-}
get : k -> EveryDictList k v -> Maybe v
get =
    AllDictList.get


{-| Determine whether a key is in the dictionary.
-}
member : k -> EveryDictList k v -> Bool
member =
    AllDictList.member


{-| Determine the number of key-value pairs in the dictionary.
-}
size : EveryDictList k v -> Int
size =
    AllDictList.size


{-| Determine whether a dictionary is empty.
-}
isEmpty : EveryDictList k v -> Bool
isEmpty =
    AllDictList.isEmpty


{-| Insert a key-value pair into a dictionary. Replaces the value when the
keys collide, leaving the keys in the same order as they had been in.
If the key did not previously exist, it is added to the end of
the list.
-}
insert : k -> v -> EveryDictList k v -> EveryDictList k v
insert =
    AllDictList.insert


{-| Remove a key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : k -> EveryDictList k v -> EveryDictList k v
remove =
    AllDictList.remove


{-| Update the value for a specific key with a given function. Maintains
the order of the key, or inserts it at the end if it is new.
-}
update : k -> (Maybe v -> Maybe v) -> EveryDictList k v -> EveryDictList k v
update =
    AllDictList.update


{-| Create a dictionary with one key-value pair.
-}
singleton : k -> v -> EveryDictList k v
singleton =
    AllDictList.singleton toString



-- COMBINE


{-| Combine two dictionaries. If keys collide, preference is given
to the value from the first dictionary.

Keys already in the first dictionary will remain in their original order.

Keys newly added from the second dictionary will be added at the end.

So, you might think of `union` as being biased towards the first argument,
since it preserves both key-order and values from the first argument, only
adding things on the right (from the second argument) for keys that were not
present in the first. This seems to correspond best to the logic of `Dict.union`.

For a similar function that is biased towards the second argument, see `append`.
-}
union : EveryDictList k v -> EveryDictList k v -> EveryDictList k v
union =
    AllDictList.union


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary. The resulting
order of keys will be as it was in the first dictionary.
-}
intersect : EveryDictList k v -> EveryDictList k v -> EveryDictList k v
intersect =
    AllDictList.intersect


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : EveryDictList k v -> EveryDictList k v -> EveryDictList k v
diff =
    AllDictList.diff


{-| The most general way of combining two dictionaries. You provide three
accumulators for when a given key appears:

  1. Only in the left dictionary.
  2. In both dictionaries.
  3. Only in the right dictionary.

You then traverse all the keys and values, building up whatever
you want.

The keys and values from the first dictionary will be provided first,
in the order maintained by the first dictionary. Then, any keys which are
only in the second dictionary will be provided, in the order maintained
by the second dictionary.
-}
merge :
    (k -> a -> result -> result)
    -> (k -> a -> b -> result -> result)
    -> (k -> b -> result -> result)
    -> EveryDictList k a
    -> EveryDictList k b
    -> result
    -> result
merge =
    AllDictList.merge



-- TRANSFORM


{-| Apply a function to all values in a dictionary.
-}
map : (k -> a -> b) -> EveryDictList k a -> EveryDictList k b
map =
    AllDictList.map


{-| Fold over the key-value pairs in a dictionary, in order from the first
key to the last key (given the arbitrary order maintained by the dictionary).
-}
foldl : (k -> v -> b -> b) -> b -> EveryDictList k v -> b
foldl =
    AllDictList.foldl


{-| Fold over the key-value pairs in a dictionary, in order from the last
key to the first key (given the arbitrary order maintained by the dictionary.
-}
foldr : (k -> v -> b -> b) -> b -> EveryDictList k v -> b
foldr =
    AllDictList.foldr


{-| Keep a key-value pair when it satisfies a predicate.
-}
filter : (k -> v -> Bool) -> EveryDictList k v -> EveryDictList k v
filter =
    AllDictList.filter


{-| Partition a dictionary according to a predicate. The first dictionary
contains all key-value pairs which satisfy the predicate, and the second
contains the rest.
-}
partition : (k -> v -> Bool) -> EveryDictList k v -> ( EveryDictList k v, EveryDictList k v )
partition =
    AllDictList.partition



-- LISTS


{-| Get all of the keys in a dictionary, in the order maintained by the dictionary.
-}
keys : EveryDictList k v -> List k
keys =
    AllDictList.keys


{-| Get all of the values in a dictionary, in the order maintained by the dictionary.
-}
values : EveryDictList k v -> List v
values =
    AllDictList.values


{-| Convert a dictionary into an association list of key-value pairs, in the order maintained by the dictionary.
-}
toList : EveryDictList k v -> List ( k, v )
toList =
    AllDictList.toList


{-| Convert an association list into a dictionary, maintaining the order of the list.
-}
fromList : List ( k, v ) -> EveryDictList k v
fromList =
    AllDictList.fromList toString


{-| Extract a `Dict` from a dictionary
-}
toDict : EveryDictList comparable v -> Dict comparable v
toDict =
    AllDictList.toDict


{-| Given a `Dict`, create a dictionary. The keys will initially be in the
order that the `Dict` provides.
-}
fromDict : Dict comparable v -> EveryDictList comparable v
fromDict =
    AllDictList.fromDict


{-| Convert an `EveryDictList` to an `AllDictList`
-}
toAllDictList : EveryDictList k v -> AllDictList k v String
toAllDictList =
    identity


{-| Given an `AllDictList`, create an `EveryDictList`.
-}
fromAllDictList : AllDictList k v String -> EveryDictList k v
fromAllDictList =
    identity



-------------
-- Dict.Extra
-------------


{-| Takes a key-fn and a list.

Creates a dictionary which maps the key to a list of matching elements.

    mary = {id=1, name="Mary"}
    jack = {id=2, name="Jack"}
    jill = {id=1, name="Jill"}

    groupBy .id [mary, jack, jill] == EveryDictList.fromList [(1, [mary, jill]), (2, [jack])]
-}
groupBy : (a -> k) -> List a -> EveryDictList k (List a)
groupBy =
    AllDictList.groupBy toString


{-| Create a dictionary from a list of values, by passing a function that can
get a key from any such value. If the function does not return unique keys,
earlier values are discarded.

This can, for instance, be useful when constructing a dictionary from a List of
records with `id` fields:

    mary = {id=1, name="Mary"}
    jack = {id=2, name="Jack"}
    jill = {id=1, name="Jill"}

    fromListBy .id [mary, jack, jill] == EveryDictList.fromList [(1, jack), (2, jill)]
-}
fromListBy : (a -> k) -> List a -> EveryDictList k a
fromListBy =
    AllDictList.fromListBy toString


{-| Remove elements which satisfies the predicate.

    removeWhen (\_ v -> v == 1) (EveryDictList.fromList [("Mary", 1), ("Jack", 2), ("Jill", 1)]) == EveryDictList.fromList [("Jack", 2)]
-}
removeWhen : (k -> v -> Bool) -> EveryDictList k v -> EveryDictList k v
removeWhen =
    AllDictList.removeWhen


{-| Remove a key-value pair if its key appears in the set.
-}
removeMany : Set comparable -> EveryDictList comparable v -> EveryDictList comparable v
removeMany =
    AllDictList.removeMany


{-| Keep a key-value pair if its key appears in the set.
-}
keepOnly : Set comparable -> EveryDictList comparable v -> EveryDictList comparable v
keepOnly =
    AllDictList.keepOnly


{-| Apply a function to all keys in a dictionary.
-}
mapKeys : (k1 -> k2) -> EveryDictList k1 v -> EveryDictList k2 v
mapKeys =
    AllDictList.mapKeys toString
