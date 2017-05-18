module Toolkit.Helpers exposing
  ( roundTo, toBool, isOneOf, isInRange, isBetween, try, maybe2Tuple
  , maybe3Tuple, maybe4Tuple, maybeList, result2Tuple, result3Tuple
  , result4Tuple, resultList, getNth, unique, take2Tuple, take3Tuple, take4Tuple
  , list2Tuple, list3Tuple, list4Tuple, unzip3, unzip4, zip, zip3, zip4, first3
  , second3, third3, first4, second4, third4, fourth4, map2Tuple, map3Tuple
  , map4Tuple, curry3, curry4, uncurry3, uncurry4, apply2, apply3, apply4
  , applyList
  )


{-|

## Some generic helper functions for type conversion, error handling, and working with lists, tuples, and functions

This is my personal library of helper functions for writing clean,
unidirectional, semantically pleasing Elm code. I've included all of these
functions in one module so that I can easily import them into other projects.

# Rounding Numbers
@docs roundTo

# String-to-Bool Conversion
@docs toBool

# Test Functions
@docs isOneOf, isInRange, isBetween

# Error Handling with `Result` Functions
@docs try

# Error Handling with Multiple `Maybe` Values
@docs maybe2Tuple, maybe3Tuple, maybe4Tuple, maybeList

# Error Handling with Multiple `Result` Values
@docs result2Tuple, result3Tuple, result4Tuple, resultList

# Getting a Value from a List
@docs getNth

# Removing Duplicate Values from a List
@docs unique

# List-Tuple Conversions
@docs take2Tuple, take3Tuple, take4Tuple, list2Tuple, list3Tuple, list4Tuple
@docs unzip3, unzip4, zip, zip3, zip4

# Getting Values from Tuples
@docs first3, second3, third3, first4, second4, third4, fourth4

# Mapping Functions to Tuples
@docs map2Tuple, map3Tuple, map4Tuple

# Currying and Uncurrying
@docs curry3, curry4, uncurry3, uncurry4

# Applying Multiple Functions to Data
@docs apply2, apply3, apply4, applyList

-}


import Set


-- ROUNDING NUMBERS

{-| Round a `Float` to a given number of decimal places

    pi |> roundTo 2      --> 3.14
    pi |> roundTo 0      --> 3
    1234 |> roundTo -2   --> 1200
-}
roundTo : Int -> Float -> Float
roundTo place number =
  let
    multiplier =
      place
        |> (^) 10
        |> toFloat

  in
    number
      |> (*) multiplier
      |> round
      |> toFloat
      |> flip (/) multiplier


-- STRING-TO-BOOL CONVERSION

{-| Convert a boolean string to a `Bool`, ignoring case

    toBool "true"     --> Ok True
    toBool "True"     --> Ok True
    toBool "false"    --> Ok False
    toBool "FALSE"    --> Ok False
    toBool "blah"     --> Err "String argument must be 'true' or 'false' (case ignored)"
-}
toBool : String -> Result String Bool
toBool boolString =
  case boolString |> String.toLower of
    "true" ->
      Ok True

    "false" ->
      Ok False

    _ ->
      Err "String argument must be 'true' or 'false' (case ignored)"


--TEST FUNCTIONS

{-| Given a list and a test value, returns `True` if the list contains a value
equal to the test value.

Equivalent to
[List.member](http://package.elm-lang.org/packages/elm-lang/core/latest/List#member)
with the arguments flipped
-}
isOneOf : List a -> a -> Bool
isOneOf list value =
  List.member value list


{-| Given a pair of values defining an interval and a test value, returns `True`
if the test value falls within the interval, *including* its endpoints
-}
isInRange : (comparable, comparable) -> comparable -> Bool
isInRange (min, max) value =
  value >= min && value <= max


{-| Given a pair of values defining an interval and a test value, returns `True`
if the test value falls strictly *between* the endpoints of the interval, such
that a test value equal to one of the endpoints will return `False`
-}
isBetween : (comparable, comparable) -> comparable -> Bool
isBetween (min, max) value =
  value > min && value < max


-- ERROR HANDLING WITH RESULT FUNCTIONS

{-| Apply a function that returns a `Result` value, with the initial value as
the default (equivalent to `f x |> Result.withDefault x`). Note that the type
returned in an `Ok` result must match the type of the initial value.
-}
try : (a -> Result x a) -> a -> a
try resultFunction initialValue =
  case initialValue |> resultFunction of
    Ok resultValue ->
      resultValue

    Err _ ->
      initialValue


--ERROR HANDLING WITH MULTIPLE MAYBES

{-| Given a 2-tuple of `Maybe` values, if both values are defined, return `Just`
the 2-tuple of values; otherwise, return `Nothing`

    maybe2Tuple (Just 1, Just 2)    --> Just (1,2)
    maybe2Tuple (Just 1, Nothing)    --> Nothing
-}
maybe2Tuple : (Maybe a, Maybe b) -> Maybe (a, b)
maybe2Tuple tuple =
  case tuple of
    (Just a, Just b) ->
      Just (a, b)

    _ ->
      Nothing


{-| Given a 3-tuple of `Maybe` values, if all three values are defined, return
`Just` the 3-tuple of values; otherwise, return `Nothing`
-}
maybe3Tuple : (Maybe a, Maybe b, Maybe c) -> Maybe (a, b, c)
maybe3Tuple tuple =
  case tuple of
    (Just a, Just b, Just c) ->
      Just (a, b, c)

    _ ->
      Nothing


{-| Given a 4-tuple of `Maybe` values, if all four values are defined, return
`Just` the 4-tuple of values; otherwise, return `Nothing`
-}
maybe4Tuple : (Maybe a, Maybe b, Maybe c, Maybe d) -> Maybe (a, b, c, d)
maybe4Tuple tuple =
  case tuple of
    (Just a, Just b, Just c, Just d) ->
      Just (a, b, c, d)

    _ ->
      Nothing


{-| Given a list of `Maybe` values, if all values are defined, return
`Just` the list of values; otherwise, return `Nothing`. When passed an empty
list, returns `Just` an empty list.

    maybeList [Just 1, Just 2]    --> Just [1,2]
    maybeList [Just 1, Nothing]   --> Nothing
    maybeList []                  --> Just []

-}
maybeList : List (Maybe a) -> Maybe (List a)
maybeList list =
  case list |> List.take 1 of
    [ Just value ] ->
      list
        |> List.drop 1
        |> maybeList
        |> Maybe.map ((::) value)

    [] ->
      Just []

    _ ->
      Nothing


--ERROR HANDLING WITH MULTIPLE RESULTS

{-| Given a 2-tuple of `Result` values, if both values are `Ok`, return an `Ok`
result containing the 2-tuple of values; otherwise, return an `Err` value.

    result2Tuple "ERROR" (Ok 1, Ok 2)       --> Ok (1,2)
    result2Tuple "ERROR" (Ok 1, Err "..")   --> Err "ERROR"
-}
result2Tuple : x -> (Result x a, Result x b) -> Result x (a, b)
result2Tuple error tuple =
  case tuple of
    (Ok a, Ok b) ->
      Ok (a, b)

    _ ->
      Err error


{-| Given a 3-tuple of `Result` values, if all three values are `Ok`, return an
`Ok` result containing the 3-tuple of values; otherwise, return an `Err`
value.
-}
result3Tuple : x -> (Result x a, Result x b, Result x c) -> Result x (a, b, c)
result3Tuple error tuple =
  case tuple of
    (Ok a, Ok b, Ok c) ->
      Ok (a, b, c)

    _ ->
      Err error


{-| Given a 4-tuple of `Result` values, if all three values are `Ok`, return an
`Ok` result containing the 4-tuple of values; otherwise, return an `Err`
value.
-}
result4Tuple : x -> (Result x a, Result x b, Result x c, Result x d) -> Result x (a, b, c, d)
result4Tuple error tuple =
  case tuple of
    (Ok a, Ok b, Ok c, Ok d) ->
      Ok (a, b, c, d)

    _ ->
      Err error


{-| Given a list of `Result` values, if all values are `Ok`, return an `Ok`
result containing the list of values; otherwise, return an error message. When
passed an empty list, returns `Ok []`.

    resultList "ERROR" [Ok 1, Ok 2]       --> Ok [1,2]
    resultList "ERROR" [Ok 1, Err ".."]   --> Err "ERROR"
    resultList []                         --> Ok []

-}
resultList : x -> List (Result x a) -> Result x (List a)
resultList errorMsg list =
  case list |> List.take 1 of
    [ Ok value ] ->
      list
        |> List.drop 1
        |> resultList errorMsg
        |> Result.map ((::) value)

    [] ->
      Ok []

    _ ->
      Err errorMsg


-- GETTING A VALUE FROM A LIST

{-| Get the value at the nth place of a list without converting the list to an
array; returns `Nothing` if the list contains fewer than `n + 1` items, or if
`n` is negative

    getNth 0 [1, 3, 9, 27]    --> Just 1
    getNth 3 [1, 3, 9, 27]    --> Just 27
    getNth 4 [1, 3, 9, 27]    --> Nothing
    getNth -1 [1, 3, 9, 27]   --> Nothing

-}
getNth : Int -> List a -> Maybe a
getNth n list =
  if n < 0 then
    Nothing

  else
    list
      |> List.drop n
      |> List.head


-- REMOVING DUPLICATE VALUES FROM A LIST
{-| Given a list of values, returns the unique values as a list sorted from
highest to lowest
-}
unique : List comparable -> List comparable
unique list =
  list
    |> Set.fromList
    |> Set.toList


-- LIST-TUPLE CONVERSIONS

{-| Returns the first two items in a list as a 2-tuple, or `Nothing` if the list
contains fewer than two items

    take2Tuple [1,2]    --> Just (1,2)
    take2Tuple [1,2,3]  --> Just (1,2)
    take2Tuple [1]      --> Nothing
-}
take2Tuple : List a -> Maybe (a, a)
take2Tuple list =
  list
    |> apply2 (getNth 0, getNth 1)
    |> maybe2Tuple


{-| Returns the first three items in a list as a 3-tuple, or `Nothing` if the
list contains fewer than three items
-}
take3Tuple : List a -> Maybe (a, a, a)
take3Tuple list =
  list
    |> apply3 (getNth 0, getNth 1, getNth 2)
    |> maybe3Tuple


{-| Returns the first four items in a list as a 4-tuple, or `Nothing` if the
list contains fewer than four items
-}
take4Tuple : List a -> Maybe (a, a, a, a)
take4Tuple list =
    list
      |> apply4 (getNth 0, getNth 1, getNth 2, getNth 3)
      |> maybe4Tuple


{-| Given a 2-tuple where both values are of the same type, return a list
containing those values
-}
list2Tuple : (a, a) -> List a
list2Tuple (a, b) =
  [a, b]


{-| Given a 3-tuple where all three values are of the same type, return a list
containing those values
-}
list3Tuple : (a, a, a) -> List a
list3Tuple (a, b, c) =
  [a, b, c]


{-| Given a 4-tuple where all four values are of the same type, return a list
containing those values
-}
list4Tuple : (a, a, a, a) -> List a
list4Tuple (a, b, c, d) =
  [a, b, c, d]


{-| Convert a 3-tuple of lists to a list of 3-tuples (see
[List.unzip](package.elm-lang.org/packages/elm-lang/core/latest/List#unzip))
-}
unzip3 : (List a, List b, List c) -> List (a, b, c)
unzip3 (list1, list2, list3) =
  List.map3 (\a b c -> (a, b, c)) list1 list2 list3


{-| Convert a 4-tuple of lists to a list of 4-tuples
-}
unzip4 : (List a, List b, List c, List d) -> List (a, b, c, d)
unzip4 (list1, list2, list3, list4) =
  List.map4 (\a b c d -> (a, b, c, d)) list1 list2 list3 list4


{-| Convert a 2-tuple of lists to a list of 2-tuples

    zip ([0,17,1337], [True,False,True])

    --> [(0, True), (17, False), (1337, True)]

-}
zip : (List a, List b) -> List (a, b)
zip (list1, list2) =
  List.map2 (,) list1 list2


{-| Convert a 3-tuple of lists to a list of 3-tuples
-}
zip3 : (List a, List b, List c) -> List (a, b, c)
zip3 (list1, list2, list3) =
  List.map3 (\a b c -> (a, b, c)) list1 list2 list3


{-| Convert a 4-tuple of lists to a list of 4-tuples
-}
zip4 : (List a, List b, List c, List d) -> List (a, b, c, d)
zip4 (list1, list2, list3, list4) =
  List.map4 (\a b c d -> (a, b, c, d)) list1 list2 list3 list4


--GETTING VALUES FROM TUPLES

{-| Return the first value of a 3-tuple
-}
first3 : (a, b, c) -> a
first3 (a, b, c) =
  a

{-| Return the second value of a 3-tuple
-}
second3 : (a, b, c) -> b
second3 (a, b, c) =
  b

{-| Return the third value of a 3-tuple
-}
third3 : (a, b, c) -> c
third3 (a, b, c) =
  c

{-| Return the first value of a 4-tuple
-}
first4 : (a, b, c, d) -> a
first4 (a, b, c, d) =
  a

{-| Return the second value of a 4-tuple
-}
second4 : (a, b, c, d) -> b
second4 (a, b, c, d) =
  b

{-| Return the third value of a 4-tuple
-}
third4 : (a, b, c, d) -> c
third4 (a, b, c, d) =
  c

{-| Return the fourth value of a 4-tuple
-}
fourth4 : (a, b, c, d) -> d
fourth4 (a, b, c, d) =
  d


--MAPPING FUNCTIONS TO TUPLES

{-| Apply a function to both values in a 2-tuple and return the results as a
2-tuple
-}
map2Tuple : (a -> b) -> (a, a) -> (b, b)
map2Tuple f (a1, a2) =
  (f a1, f a2)


{-| Apply a function to all 3 values in a 3-tuple and return the results as a
3-tuple
-}
map3Tuple : (a -> b) -> (a, a, a) -> (b, b, b)
map3Tuple f (a1, a2, a3) =
  (f a1, f a2, f a3)


{-| Apply a function to all 4 values in a 4-tuple and return the results as a
4-tuple
-}
map4Tuple : (a -> b) -> (a, a, a, a) -> (b, b, b, b)
map4Tuple f (a1, a2, a3, a4) =
  (f a1, f a2, f a3, f a4)


--CURRYING AND UNCURRYING

{-| [`curry`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#curry)
with 3 parameters
-}
curry3 : ((a, b, c) -> d) -> a -> b -> c -> d
curry3 f a b c =
  f (a, b, c)


{-| [`curry`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#curry)
with 4 parameters
-}
curry4 : ((a, b, c, d) -> e) -> a -> b -> c -> d -> e
curry4 f a b c d =
  f (a, b, c, d)


{-| [`uncurry`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#uncurry)
with 3 parameters
-}
uncurry3 : (a -> b -> c -> d) -> (a, b, c) -> d
uncurry3 f (a, b, c) =
  f a b c


{-| [`uncurry`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#uncurry)
with 4 parameters
-}
uncurry4 : (a -> b -> c -> d -> e) -> (a, b, c, d) -> e
uncurry4 f (a, b, c, d) =
  f a b c d


--APPLYING MULTIPLE FUNCTIONS TO DATA

{-| Given a tuple containing two functions and a value accepted by both
functions, return a tuple containing the two results
-}
apply2 : (a -> b, a -> c) -> a -> (b, c)
apply2 (f1, f2) a =
  (f1 a, f2 a)


{-| Given a tuple containing three functions and a value accepted by all three
functions, return a tuple containing the three results
-}
apply3 : (a -> b, a -> c, a -> d) -> a -> (b, c, d)
apply3 (f1, f2, f3) a =
  (f1 a, f2 a, f3 a)


{-| Given a tuple containing four functions and a value accepted by all four
functions, return a tuple containing the four results
-}
apply4 : (a -> b, a -> c, a -> d, a -> e) -> a -> (b, c, d, e)
apply4 (f1, f2, f3, f4) a =
  (f1 a, f2 a, f3 a, f4 a)


{-| Given a list containing any number of functions and a value accepted by
every function in the list, return a list containing all of the results. Note
that to use `applyList`, all of the results must be of the same type, which is
not the case for the apply functions that return tuples.
-}
applyList : List (a -> b) -> a -> List b
applyList fList data =
  let
    getNextResult (data, fList) =
      case fList |> List.head of
        Just f ->
          [ data |> f ]

        Nothing ->
          []

    applyNextFun (data, fList) resultList =
      case fList of
        Just fList ->
          (data, fList)
            |> getNextResult
            |> (++) resultList
            |> applyNextFun (data, fList |> List.tail)

        Nothing ->
          resultList

  in
    []
      |> applyNextFun (data, Just fList)
