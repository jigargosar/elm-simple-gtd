module DictList
    exposing
        ( DictList
          -- originally from `Dict`
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

{-| Have you ever wanted a `Dict`, but you need to maintain an arbitrary
ordering of keys? Or, a `List`, but you want to efficiently lookup values
by a key? With `DictList`, now you can!

`DictList` implements the full API for `Dict` (and should be a drop-in
replacement for it). However, instead of ordering things from lowest
key to highest key, it allows for an arbitrary ordering.

We also implement most of the API for `List`. However, the API is not
identical, since we need to account for both keys and values.

An alternative would be to maintain your own "association list" -- that is,
a `List (k, v)` instead of a `DictList k v`. You can move back and forth
between an association list and a `DictList` via `toList` and `fromList`.

# DictList

@docs DictList, eq

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

import AllDictList exposing (AllDictList, RelativePosition(..))
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
type alias DictList k v =
    AllDictList k v k



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
decodeObject : Decoder a -> Decoder (DictList String a)
decodeObject =
    AllDictList.decodeObject


{-| This function produces a decoder you can use if you can decode a list of your keys,
and given a key, you can produce a decoder for the corresponding value. The
order within the dictionary will be the order of your list of keys.
-}
decodeWithKeys : List comparable -> (comparable -> Decoder value) -> Decoder (DictList comparable value)
decodeWithKeys =
    AllDictList.decodeWithKeys identity


{-| Like `decodeWithKeys`, but you supply a decoder for the keys, rather than the keys themselves.

Note that the starting point for all decoders will be the same place, so you need to construct your
decoders in a way that makes that work.
-}
decodeKeysAndValues : Decoder (List comparable) -> (comparable -> Decoder value) -> Decoder (DictList comparable value)
decodeKeysAndValues =
    AllDictList.decodeKeysAndValues identity


{-| Given a decoder for the value, and a way of turning the value into a key,
decode an array of values into a dictionary. The order within the dictionary
will be the order of the JSON array.
-}
decodeArray : (value -> comparable) -> Decoder value -> Decoder (DictList comparable value)
decodeArray =
    AllDictList.decodeArray identity


{-| Decodes a JSON array into the DictList. You supply two decoders. Given an element
of your JSON array, the first decoder should decode the key, and the second decoder
should decode the value.
-}
decodeArray2 : Decoder comparable -> Decoder value -> Decoder (DictList comparable value)
decodeArray2 =
    AllDictList.decodeArray2 identity



----------------------
-- From `List` in core
----------------------


{-| Insert a key-value pair at the front. Moves the key to the front if
    it already exists.
-}
cons : comparable -> value -> DictList comparable value -> DictList comparable value
cons =
    AllDictList.cons


{-| Gets the first key with its value.
-}
head : DictList comparable value -> Maybe ( comparable, value )
head =
    AllDictList.head


{-| Extract the rest of the dictionary, without the first key/value pair.
-}
tail : DictList comparable value -> Maybe (DictList comparable value)
tail =
    AllDictList.tail


{-| Like `map` but the function is also given the index of each
element (starting at zero).
-}
indexedMap : (Int -> comparable -> a -> b) -> DictList comparable a -> DictList comparable b
indexedMap =
    AllDictList.indexedMap


{-| Apply a function that may succeed to all key-value pairs, but only keep
the successes.
-}
filterMap : (comparable -> a -> Maybe b) -> DictList comparable a -> DictList comparable b
filterMap =
    AllDictList.filterMap


{-| The number of key-value pairs in the dictionary.
-}
length : DictList comparable value -> Int
length =
    AllDictList.length


{-| Reverse the order of the key-value pairs.
-}
reverse : DictList comparable value -> DictList comparable value
reverse =
    AllDictList.reverse


{-| Determine if all elements satisfy the predicate.
-}
all : (comparable -> value -> Bool) -> DictList comparable value -> Bool
all =
    AllDictList.all


{-| Determine if any elements satisfy the predicate.
-}
any : (comparable -> value -> Bool) -> DictList comparable value -> Bool
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
append : DictList comparable value -> DictList comparable value -> DictList comparable value
append =
    AllDictList.append


{-| Concatenate a bunch of dictionaries into a single dictionary.

Works from left to right, applying `append` as it goes.
-}
concat : List (DictList comparable value) -> DictList comparable value
concat =
    AllDictList.concat identity


{-| Get the sum of the values.
-}
sum : DictList comparable number -> number
sum =
    AllDictList.sum


{-| Get the product of the values.
-}
product : DictList comparable number -> number
product =
    AllDictList.product


{-| Find the maximum value. Returns `Nothing` if empty.
-}
maximum : DictList comparable1 comparable2 -> Maybe comparable2
maximum =
    AllDictList.maximum


{-| Find the minimum value. Returns `Nothing` if empty.
-}
minimum : DictList comparable1 comparable2 -> Maybe comparable2
minimum =
    AllDictList.minimum


{-| Take the first *n* values.
-}
take : Int -> DictList comparable value -> DictList comparable value
take =
    AllDictList.take


{-| Drop the first *n* values.
-}
drop : Int -> DictList comparable value -> DictList comparable value
drop =
    AllDictList.drop


{-| Sort values from lowest to highest
-}
sort : DictList comparable1 comparable2 -> DictList comparable1 comparable2
sort =
    AllDictList.sort


{-| Sort values by a derived property.
-}
sortBy : (value -> comparable) -> DictList comparable2 value -> DictList comparable2 value
sortBy =
    AllDictList.sortBy


{-| Sort values with a custom comparison function.
-}
sortWith : (value -> value -> Order) -> DictList comparable value -> DictList comparable value
sortWith =
    AllDictList.sortWith



----------------
-- List-oriented
----------------


{-| Given a key, what index does that key occupy (0-based) in the
order maintained by the dictionary?
-}
indexOfKey : comparable -> DictList comparable value -> Maybe Int
indexOfKey =
    AllDictList.indexOfKey


{-| Given a key, get the key and value at the next position.
-}
next : comparable -> DictList comparable value -> Maybe ( comparable, value )
next =
    AllDictList.next


{-| Given a key, get the key and value at the previous position.
-}
previous : comparable -> DictList comparable value -> Maybe ( comparable, value )
previous =
    AllDictList.previous


{-| Gets the key at the specified index (0-based).
-}
getKeyAt : Int -> DictList comparable value -> Maybe comparable
getKeyAt =
    AllDictList.getKeyAt


{-| Gets the key and value at the specified index (0-based).
-}
getAt : Int -> DictList comparable value -> Maybe ( comparable, value )
getAt =
    AllDictList.getAt


{-| Insert a key-value pair into a dictionary, replacing an existing value if
the keys collide. The first parameter represents an existing key, while the
second parameter is the new key. The new key and value will be inserted after
the existing key (even if the new key already exists). If the existing key
cannot be found, the new key/value pair will be inserted at the end.
-}
insertAfter : comparable -> comparable -> v -> DictList comparable v -> DictList comparable v
insertAfter =
    AllDictList.insertAfter


{-| Insert a key-value pair into a dictionary, replacing an existing value if
the keys collide. The first parameter represents an existing key, while the
second parameter is the new key. The new key and value will be inserted before
the existing key (even if the new key already exists). If the existing key
cannot be found, the new key/value pair will be inserted at the beginning.
-}
insertBefore : comparable -> comparable -> v -> DictList comparable v -> DictList comparable v
insertBefore =
    AllDictList.insertBefore


{-| Get the position of a key relative to the previous key (or next, if the
first key). Returns `Nothing` if the key was not found.
-}
relativePosition : comparable -> DictList comparable v -> Maybe (RelativePosition comparable)
relativePosition =
    AllDictList.relativePosition


{-| Gets the key-value pair currently at the indicated relative position.
-}
atRelativePosition : RelativePosition comparable -> DictList comparable value -> Maybe ( comparable, value )
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
insertRelativeTo : RelativePosition comparable -> comparable -> v -> DictList comparable v -> DictList comparable v
insertRelativeTo =
    AllDictList.insertRelativeTo



--------------
-- From `Dict`
--------------


{-| Create an empty dictionary.
-}
empty : DictList comparable v
empty =
    AllDictList.empty identity


{-| Element equality.
-}
eq : DictList comparable v -> DictList comparable v -> Bool
eq =
    AllDictList.eq


{-| Get the value associated with a key. If the key is not found, return
`Nothing`.
-}
get : comparable -> DictList comparable v -> Maybe v
get =
    AllDictList.get


{-| Determine whether a key is in the dictionary.
-}
member : comparable -> DictList comparable v -> Bool
member =
    AllDictList.member


{-| Determine the number of key-value pairs in the dictionary.
-}
size : DictList comparable v -> Int
size =
    AllDictList.size


{-| Determine whether a dictionary is empty.
-}
isEmpty : DictList comparable v -> Bool
isEmpty =
    AllDictList.isEmpty


{-| Insert a key-value pair into a dictionary. Replaces the value when the
keys collide, leaving the keys in the same order as they had been in.
If the key did not previously exist, it is added to the end of
the list.
-}
insert : comparable -> v -> DictList comparable v -> DictList comparable v
insert =
    AllDictList.insert


{-| Remove a key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : comparable -> DictList comparable v -> DictList comparable v
remove =
    AllDictList.remove


{-| Update the value for a specific key with a given function. Maintains
the order of the key, or inserts it at the end if it is new.
-}
update : comparable -> (Maybe v -> Maybe v) -> DictList comparable v -> DictList comparable v
update =
    AllDictList.update


{-| Create a dictionary with one key-value pair.
-}
singleton : comparable -> v -> DictList comparable v
singleton =
    AllDictList.singleton identity



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
union : DictList comparable v -> DictList comparable v -> DictList comparable v
union =
    AllDictList.union


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary. The resulting
order of keys will be as it was in the first dictionary.
-}
intersect : DictList comparable v -> DictList comparable v -> DictList comparable v
intersect =
    AllDictList.intersect


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : DictList comparable v -> DictList comparable v -> DictList comparable v
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
    (comparable -> a -> result -> result)
    -> (comparable -> a -> b -> result -> result)
    -> (comparable -> b -> result -> result)
    -> DictList comparable a
    -> DictList comparable b
    -> result
    -> result
merge =
    AllDictList.merge



-- TRANSFORM


{-| Apply a function to all values in a dictionary.
-}
map : (comparable -> a -> b) -> DictList comparable a -> DictList comparable b
map =
    AllDictList.map


{-| Fold over the key-value pairs in a dictionary, in order from the first
key to the last key (given the arbitrary order maintained by the dictionary).
-}
foldl : (comparable -> v -> b -> b) -> b -> DictList comparable v -> b
foldl =
    AllDictList.foldl


{-| Fold over the key-value pairs in a dictionary, in order from the last
key to the first key (given the arbitrary order maintained by the dictionary.
-}
foldr : (comparable -> v -> b -> b) -> b -> DictList comparable v -> b
foldr =
    AllDictList.foldr


{-| Keep a key-value pair when it satisfies a predicate.
-}
filter : (comparable -> v -> Bool) -> DictList comparable v -> DictList comparable v
filter =
    AllDictList.filter


{-| Partition a dictionary according to a predicate. The first dictionary
contains all key-value pairs which satisfy the predicate, and the second
contains the rest.
-}
partition : (comparable -> v -> Bool) -> DictList comparable v -> ( DictList comparable v, DictList comparable v )
partition =
    AllDictList.partition



-- LISTS


{-| Get all of the keys in a dictionary, in the order maintained by the dictionary.
-}
keys : DictList comparable v -> List comparable
keys =
    AllDictList.keys


{-| Get all of the values in a dictionary, in the order maintained by the dictionary.
-}
values : DictList comparable v -> List v
values =
    AllDictList.values


{-| Convert a dictionary into an association list of key-value pairs, in the order maintained by the dictionary.
-}
toList : DictList comparable v -> List ( comparable, v )
toList =
    AllDictList.toList


{-| Convert an association list into a dictionary, maintaining the order of the list.
-}
fromList : List ( comparable, v ) -> DictList comparable v
fromList =
    AllDictList.fromList identity


{-| Extract a `Dict` from a `DictList`
-}
toDict : DictList comparable v -> Dict comparable v
toDict =
    AllDictList.toDict


{-| Given a `Dict`, create a `DictList`. The keys will initially be in the
order that the `Dict` provides.
-}
fromDict : Dict comparable v -> DictList comparable v
fromDict =
    AllDictList.fromDict


{-| Convert a `DictList` to an `AllDictList`
-}
toAllDictList : DictList comparable v -> AllDictList comparable v comparable
toAllDictList =
    identity


{-| Given an `AllDictList`, create a `DictList`.
-}
fromAllDictList : AllDictList comparable v comparable -> DictList comparable v
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

    groupBy .id [mary, jack, jill] == DictList.fromList [(1, [mary, jill]), (2, [jack])]
-}
groupBy : (a -> comparable) -> List a -> DictList comparable (List a)
groupBy =
    AllDictList.groupBy identity


{-| Create a dictionary from a list of values, by passing a function that can
get a key from any such value. If the function does not return unique keys,
earlier values are discarded.

This can, for instance, be useful when constructing a dictionary from a List of
records with `id` fields:

    mary = {id=1, name="Mary"}
    jack = {id=2, name="Jack"}
    jill = {id=1, name="Jill"}

    fromListBy .id [mary, jack, jill] == DictList.fromList [(1, jack), (2, jill)]
-}
fromListBy : (a -> comparable) -> List a -> DictList comparable a
fromListBy =
    AllDictList.fromListBy identity


{-| Remove elements which satisfies the predicate.

    removeWhen (\_ v -> v == 1) (DictList.fromList [("Mary", 1), ("Jack", 2), ("Jill", 1)]) == DictList.fromList [("Jack", 2)]
-}
removeWhen : (comparable -> v -> Bool) -> DictList comparable v -> DictList comparable v
removeWhen =
    AllDictList.removeWhen


{-| Remove a key-value pair if its key appears in the set.
-}
removeMany : Set comparable -> DictList comparable v -> DictList comparable v
removeMany =
    AllDictList.removeMany


{-| Keep a key-value pair if its key appears in the set.
-}
keepOnly : Set comparable -> DictList comparable v -> DictList comparable v
keepOnly =
    AllDictList.keepOnly


{-| Apply a function to all keys in a dictionary.
-}
mapKeys : (comparable1 -> comparable2) -> DictList comparable1 v -> DictList comparable2 v
mapKeys =
    AllDictList.mapKeys identity
