module DictListTests exposing (..)

{-| These are tests of specifically `DictList` behaviour ... that is,
things not necessarily tested by the `DictTests` or the `ListTests`.
-}

import Arithmetic exposing (isEven)
import Dict
import DictList exposing (DictList)
import Expect
import Fuzz exposing (Fuzzer)
import Json.Decode as JD exposing (Decoder, field)
import List.Extra
import Result exposing (Result(..))
import Test exposing (..)


{-| Fuzz a DictList, given a fuzzer for the keys and values.
-}
fuzzDictList : Fuzzer comparable -> Fuzzer value -> Fuzzer (DictList comparable value)
fuzzDictList fuzzKey fuzzValue =
    Fuzz.tuple ( fuzzKey, fuzzValue )
        |> Fuzz.list
        |> Fuzz.map DictList.fromList


fuzzIntDictList : Fuzzer (DictList Int Int)
fuzzIntDictList =
    fuzzDictList Fuzz.int Fuzz.int


{-| We make our own JSON string because Elm doesn't normally promise
anything about the order of values in a JSON object. So, we make sure
that the order in the JSON string is well-known, so we can test
what happens.

We also reject duplicate keys (since that would be unexpected JSON).

In addition to the JSON string, we return what we would expect from
DictList after the string is decoded.
-}
jsonObjectAndExpectedResult : Fuzzer ( String, DictList String Int )
jsonObjectAndExpectedResult =
    Fuzz.tuple ( Fuzz.int, Fuzz.int )
        |> Fuzz.list
        |> Fuzz.map
            (\list ->
                let
                    go ( key, value ) ( json, expected ) =
                        if DictList.member (toString key) expected then
                            ( json, expected )
                        else
                            ( ("\"" ++ toString key ++ "\": " ++ toString value) :: json
                            , DictList.cons (toString key) value expected
                            )
                in
                    list
                        |> List.foldr go ( [], DictList.empty )
                        |> (\( json, expected ) ->
                                ( "{" ++ String.join ", " json ++ "}"
                                , expected
                                )
                           )
            )


{-| Like the above, but produces a JSON array.
-}
jsonArrayAndExpectedResult : Fuzzer ( String, DictList Int ValueWithId )
jsonArrayAndExpectedResult =
    Fuzz.tuple ( Fuzz.int, Fuzz.int )
        |> Fuzz.list
        |> Fuzz.map
            (\list ->
                let
                    go ( key, value ) ( json, expected ) =
                        if DictList.member key expected then
                            ( json, expected )
                        else
                            ( ("{\"id\": " ++ toString key ++ ", \"value\": " ++ toString value ++ "}") :: json
                            , DictList.cons key (ValueWithId key value) expected
                            )
                in
                    list
                        |> List.foldr go ( [], DictList.empty )
                        |> (\( json, expected ) ->
                                ( "[" ++ String.join ", " json ++ "]"
                                , expected
                                )
                           )
            )


type alias ValueWithId =
    { id : Int
    , value : Int
    }


decodeValueWithId : Decoder ValueWithId
decodeValueWithId =
    JD.map2 ValueWithId
        (field "id" JD.int)
        (field "value" JD.int)


{-| Like the above, but where the ID is only the key, not included in the object.
So, the JSON looks like:

    [ { "id" : 7
      , "value" : 234
      }
    , { "id" : 8
      , "value": 467
      }
    ]

And, in the resulting DictList, the ID is only in the key, not used in the value.
-}
jsonArray2AndExpectedResult : Fuzzer ( String, DictList Int ValueWithoutId )
jsonArray2AndExpectedResult =
    Fuzz.tuple ( Fuzz.int, Fuzz.int )
        |> Fuzz.list
        |> Fuzz.map
            (\list ->
                let
                    go ( key, value ) ( json, expected ) =
                        if DictList.member key expected then
                            ( json, expected )
                        else
                            ( ("{\"id\": " ++ toString key ++ ", \"value\": " ++ toString value ++ "}") :: json
                            , DictList.cons key (ValueWithoutId value) expected
                            )
                in
                    list
                        |> List.foldr go ( [], DictList.empty )
                        |> (\( json, expected ) ->
                                ( "[" ++ String.join ", " json ++ "]"
                                , expected
                                )
                           )
            )


type alias ValueWithoutId =
    { value : Int
    }


decodeKeyForArray2 : Decoder Int
decodeKeyForArray2 =
    field "id" JD.int


decodeValueWithoutId : Decoder ValueWithoutId
decodeValueWithoutId =
    JD.map ValueWithoutId
        (field "value" JD.int)


{-| Like `jsonObjectAndExpectedResult`, but the JSON looks like this:

    { keys: [ ]
    , dict: {  }
    }

... that is, we list an array of keys separately, so that we can preserve
order.
-}
jsonKeysObjectAndExpectedResult : Fuzzer ( String, DictList String Int )
jsonKeysObjectAndExpectedResult =
    Fuzz.tuple ( Fuzz.int, Fuzz.int )
        |> Fuzz.list
        |> Fuzz.map
            (\list ->
                let
                    go ( key, value ) ( jsonKeys, jsonDict, expected ) =
                        if DictList.member (toString key) expected then
                            ( jsonKeys, jsonDict, expected )
                        else
                            ( ("\"" ++ toString key ++ "\"") :: jsonKeys
                            , ("\"" ++ toString key ++ "\": " ++ toString value) :: jsonDict
                            , DictList.cons (toString key) value expected
                            )
                in
                    list
                        |> List.foldr go ( [], [], DictList.empty )
                        |> (\( jsonKeys, jsonDict, expected ) ->
                                let
                                    keys =
                                        "\"keys\": [" ++ String.join ", " jsonKeys ++ "]"

                                    dict =
                                        "\"dict\": {" ++ String.join ", " jsonDict ++ "}"
                                in
                                    ( "{" ++ keys ++ ", " ++ dict ++ "}"
                                    , expected
                                    )
                           )
            )


jsonTests : Test
jsonTests =
    describe "JSON tests"
        [ fuzz jsonObjectAndExpectedResult "decodeObject gets the expected dict (not necessarily order)" <|
            \( json, expected ) ->
                json
                    |> JD.decodeString (DictList.decodeObject JD.int)
                    |> Result.map DictList.toDict
                    |> Expect.equal (Ok (DictList.toDict expected))
        , fuzz jsonArrayAndExpectedResult "decodeArray preserves order" <|
            \( json, expected ) ->
                json
                    |> JD.decodeString (DictList.decodeArray .id decodeValueWithId)
                    |> Expect.equal (Ok expected)
        , fuzz jsonArray2AndExpectedResult "decodeArray2 preserves order" <|
            \( json, expected ) ->
                json
                    |> JD.decodeString (DictList.decodeArray2 decodeKeyForArray2 decodeValueWithoutId)
                    |> Expect.equal (Ok expected)
        , fuzz jsonKeysObjectAndExpectedResult "decodeWithKeys gets expected result" <|
            \( json, expected ) ->
                let
                    keyDecoder =
                        field "keys" (JD.list JD.string)

                    valueDecoder key =
                        JD.at [ "dict", key ] JD.int
                in
                    json
                        |> JD.decodeString (DictList.decodeKeysAndValues keyDecoder valueDecoder)
                        |> Expect.equal (Ok expected)
        ]


consTest : Test
consTest =
    fuzz3 Fuzz.int Fuzz.int fuzzIntDictList "cons" <|
        \key value dictList ->
            let
                expectedSize result =
                    DictList.size result
                        |> Expect.equal
                            (if DictList.member key dictList then
                                DictList.size dictList
                             else
                                DictList.size dictList + 1
                            )

                expectedHead result =
                    DictList.head result
                        |> Expect.equal (Just ( key, value ))
            in
                DictList.cons key value dictList
                    |> Expect.all
                        [ expectedSize
                        , expectedHead
                        ]


headTailConsTest : Test
headTailConsTest =
    fuzz fuzzIntDictList "headTailCons" <|
        \subject ->
            let
                run =
                    Maybe.map2 (uncurry DictList.cons)
                        (DictList.head subject)
                        (DictList.tail subject)

                expected =
                    if DictList.size subject == 0 then
                        Nothing
                    else
                        Just subject
            in
                Expect.equal expected run


indexedMapTest : Test
indexedMapTest =
    fuzz fuzzIntDictList "indexedMap" <|
        \subject ->
            let
                go index key value =
                    { index = index
                    , key = key
                    , value = value
                    }

                listIndexes =
                    DictList.keys subject
                        |> List.indexedMap (\index _ -> index)

                expectIndexes values =
                    values
                        |> List.map .index
                        |> Expect.equal listIndexes

                expectKeys values =
                    values
                        |> List.map .key
                        |> Expect.equal (DictList.keys subject)

                expectValues values =
                    values
                        |> List.map .value
                        |> Expect.equal (DictList.values subject)
            in
                DictList.indexedMap go subject
                    |> DictList.values
                    |> Expect.all
                        [ expectIndexes
                        , expectKeys
                        , expectValues
                        ]


filterMapTest : Test
filterMapTest =
    fuzz fuzzIntDictList "filterMap" <|
        Expect.all
            [ \subject ->
                DictList.filterMap (\_ v -> Just v) subject
                    |> Expect.equal subject
            , \subject ->
                DictList.filterMap (\_ v -> Nothing) subject
                    |> Expect.equal DictList.empty
            ]


lengthTest : Test
lengthTest =
    fuzz fuzzIntDictList "length behaves like List.length" <|
        \subject ->
            subject
                |> DictList.length
                |> Expect.equal (DictList.toList subject |> List.length)


reverseTest : Test
reverseTest =
    fuzz fuzzIntDictList "reverse behaves like List.reverse" <|
        \subject ->
            subject
                |> DictList.reverse
                |> DictList.toList
                |> Expect.equal (DictList.toList subject |> List.reverse)


allTest : Test
allTest =
    fuzz fuzzIntDictList "all behaves like List.all" <|
        \subject ->
            subject
                |> DictList.all (\k v -> isEven k && isEven v)
                |> Expect.equal
                    (DictList.toList subject
                        |> List.all (\( k, v ) -> isEven k && isEven v)
                    )


anyTest : Test
anyTest =
    fuzz fuzzIntDictList "any behaves like List.any" <|
        \subject ->
            subject
                |> DictList.any (\k v -> isEven k && isEven v)
                |> Expect.equal
                    (DictList.toList subject
                        |> List.any (\( k, v ) -> isEven k && isEven v)
                    )


unionTest : Test
unionTest =
    fuzz2 fuzzIntDictList fuzzIntDictList "union" <|
        \left right ->
            DictList.union left right
                |> Expect.all
                    [ \result ->
                        -- See if we have the expected number of pairs
                        result
                            |> DictList.size
                            |> Expect.equal
                                (left
                                    |> DictList.keys
                                    |> List.append (DictList.keys right)
                                    |> List.Extra.unique
                                    |> List.length
                                )
                    , \result ->
                        -- The first part of the result should be equal to
                        -- the left side of the input, since keys from the left
                        -- remain in the original order, and we prever values from
                        -- the left where there are collisions.
                        result
                            |> DictList.take (DictList.size left)
                            |> Expect.equal left
                    , \result ->
                        -- The rest of the result should equal what was on the right,
                        -- without things which were already in left
                        result
                            |> DictList.drop (DictList.size left)
                            |> Expect.equal (DictList.filter (\k _ -> not (DictList.member k left)) right)
                    ]


appendTest : Test
appendTest =
    fuzz2 fuzzIntDictList fuzzIntDictList "append" <|
        \left right ->
            DictList.append left right
                |> Expect.all
                    [ \result ->
                        -- See if we have the expected number of pairs
                        result
                            |> DictList.size
                            |> Expect.equal
                                (left
                                    |> DictList.keys
                                    |> List.append (DictList.keys right)
                                    |> List.Extra.unique
                                    |> List.length
                                )
                    , \result ->
                        -- The last part of the result should be equal to
                        -- the right side of the input, since keys from the right
                        -- remain in the original order, and we prever values from
                        -- the right where there are collisions.
                        result
                            |> DictList.drop (DictList.size result - DictList.size right)
                            |> Expect.equal right
                    , \result ->
                        -- The rest of the result should equal what was on the left,
                        -- without things which were already on the right
                        result
                            |> DictList.take (DictList.size result - DictList.size right)
                            |> Expect.equal (DictList.filter (\k _ -> not (DictList.member k right)) left)
                    ]


concatTest : Test
concatTest =
    describe "concat"
        [ fuzz fuzzIntDictList "with one dictlist" <|
            Expect.all
                [ \subject ->
                    DictList.concat [ subject, DictList.empty ]
                        |> Expect.equal subject
                , \subject ->
                    DictList.concat [ DictList.empty, subject ]
                        |> Expect.equal subject
                , \subject ->
                    DictList.concat [ subject ]
                        |> Expect.equal subject
                ]
        , test "with empty list" <|
            \_ ->
                DictList.concat []
                    |> Expect.equal DictList.empty
        , fuzz2 fuzzIntDictList fuzzIntDictList "with two DictList" <|
            \left right ->
                DictList.concat [ left, right ]
                    |> Expect.equal (DictList.append left right)
        , fuzz3 fuzzIntDictList fuzzIntDictList fuzzIntDictList "with three DictLists" <|
            \a b c ->
                DictList.concat [ a, b, c ]
                    |> Expect.equal (DictList.append (DictList.append a b) c)
        ]


sumTest : Test
sumTest =
    fuzz fuzzIntDictList "sum" <|
        \subject ->
            DictList.sum subject
                |> Expect.equal (DictList.values subject |> List.sum)


productTest : Test
productTest =
    fuzz (fuzzDictList Fuzz.int (Fuzz.intRange -3 3)) "product" <|
        \subject ->
            DictList.product subject
                |> Expect.equal (DictList.values subject |> List.product)


maximumTest : Test
maximumTest =
    fuzz fuzzIntDictList "maximum" <|
        \subject ->
            DictList.maximum subject
                |> Expect.equal (DictList.values subject |> List.maximum)


minimumTest : Test
minimumTest =
    fuzz fuzzIntDictList "minimum" <|
        \subject ->
            DictList.minimum subject
                |> Expect.equal (DictList.values subject |> List.minimum)


takeTest : Test
takeTest =
    fuzz2 Fuzz.int fuzzIntDictList "take" <|
        \num subject ->
            subject
                |> DictList.take num
                |> DictList.toList
                |> Expect.equal (DictList.toList subject |> List.take num)


dropTest : Test
dropTest =
    fuzz2 Fuzz.int fuzzIntDictList "drop" <|
        \num subject ->
            subject
                |> DictList.drop num
                |> DictList.toList
                |> Expect.equal (DictList.toList subject |> List.drop num)


sortTest : Test
sortTest =
    fuzz fuzzIntDictList "sort" <|
        \subject ->
            subject
                |> DictList.sort
                |> DictList.toList
                |> Expect.equal (DictList.toList subject |> List.sortBy Tuple.second)


sortByTest : Test
sortByTest =
    fuzz fuzzIntDictList "sortBy" <|
        \subject ->
            let
                withRecord =
                    subject
                        |> DictList.map (\_ value -> { value = value })
            in
                withRecord
                    |> DictList.sortBy .value
                    |> DictList.toList
                    |> Expect.equal (DictList.toList withRecord |> List.sortBy (Tuple.second >> .value))


sortWithTest : Test
sortWithTest =
    fuzz fuzzIntDictList "sortWith" <|
        \subject ->
            let
                reverseOrder a b =
                    case compare a b of
                        LT ->
                            GT

                        EQ ->
                            EQ

                        GT ->
                            LT
            in
                subject
                    |> DictList.sortWith reverseOrder
                    |> DictList.toList
                    |> Expect.equal (DictList.toList subject |> List.sortWith (\( _, a ) ( _, b ) -> reverseOrder a b))



-- Some values used in the next few tests


pair1 : ( Int, Int )
pair1 =
    ( 1, 101 )


pair2 : ( Int, Int )
pair2 =
    ( 2, 102 )


pair3 : ( Int, Int )
pair3 =
    ( 3, 103 )


pairs : DictList Int Int
pairs =
    DictList.fromList [ pair1, pair2, pair3 ]


indexOfKeyTest : Test
indexOfKeyTest =
    describe "indexOfKey"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.indexOfKey 5
                    |> Expect.equal Nothing
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.indexOfKey 1
                    |> Expect.equal (Just 0)
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.indexOfKey 2
                    |> Expect.equal (Just 1)
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.indexOfKey 3
                    |> Expect.equal (Just 2)
        ]


nextTest : Test
nextTest =
    describe "next"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.next 5
                    |> Expect.equal Nothing
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.next 1
                    |> Expect.equal (Just pair2)
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.next 2
                    |> Expect.equal (Just pair3)
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.next 3
                    |> Expect.equal Nothing
        ]


previousTest : Test
previousTest =
    describe "previous"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.previous 5
                    |> Expect.equal Nothing
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.previous 1
                    |> Expect.equal Nothing
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.previous 2
                    |> Expect.equal (Just pair1)
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.previous 3
                    |> Expect.equal (Just pair2)
        ]


getKeyAtTest : Test
getKeyAtTest =
    describe "getKeyAt"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.getKeyAt 5
                    |> Expect.equal Nothing
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.getKeyAt 0
                    |> Expect.equal (Just 1)
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.getKeyAt 1
                    |> Expect.equal (Just 2)
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.getKeyAt 2
                    |> Expect.equal (Just 3)
        ]


getAtTest : Test
getAtTest =
    describe "getAt"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.getAt 5
                    |> Expect.equal Nothing
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.getAt 0
                    |> Expect.equal (Just pair1)
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.getAt 1
                    |> Expect.equal (Just pair2)
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.getAt 2
                    |> Expect.equal (Just pair3)
        ]


insertAfterTest : Test
insertAfterTest =
    describe "insertAfter"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.insertAfter 5 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , pair3
                            , ( 17, 117 )
                            ]
                        )
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.insertAfter 1 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , ( 17, 117 )
                            , pair2
                            , pair3
                            ]
                        )
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.insertAfter 2 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , ( 17, 117 )
                            , pair3
                            ]
                        )
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.insertAfter 3 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , pair3
                            , ( 17, 117 )
                            ]
                        )
        ]


insertBeforeTest : Test
insertBeforeTest =
    describe "insertBefore"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.insertBefore 5 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ ( 17, 117 )
                            , pair1
                            , pair2
                            , pair3
                            ]
                        )
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.insertBefore 1 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ ( 17, 117 )
                            , pair1
                            , pair2
                            , pair3
                            ]
                        )
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.insertBefore 2 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , ( 17, 117 )
                            , pair2
                            , pair3
                            ]
                        )
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.insertBefore 3 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , ( 17, 117 )
                            , pair3
                            ]
                        )
        ]


getTest : Test
getTest =
    fuzz2 Fuzz.int fuzzIntDictList "get" <|
        \key subject ->
            subject
                |> DictList.get key
                |> Expect.equal (DictList.toDict subject |> Dict.get key)


memberTest : Test
memberTest =
    fuzz2 Fuzz.int fuzzIntDictList "member" <|
        \key subject ->
            subject
                |> DictList.member key
                |> Expect.equal (DictList.toDict subject |> Dict.member key)


sizeTest : Test
sizeTest =
    fuzz fuzzIntDictList "size" <|
        \subject ->
            subject
                |> DictList.size
                |> Expect.equal (DictList.toDict subject |> Dict.size)


isEmptyTest : Test
isEmptyTest =
    fuzz fuzzIntDictList "isEmpty" <|
        \subject ->
            subject
                |> DictList.isEmpty
                |> Expect.equal (DictList.toDict subject |> Dict.isEmpty)


insertTest : Test
insertTest =
    describe "insert"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.insert 17 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , pair3
                            , ( 17, 117 )
                            ]
                        )
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.insert 1 117
                    |> Expect.equal
                        (DictList.fromList
                            [ ( 1, 117 )
                            , pair2
                            , pair3
                            ]
                        )
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.insert 2 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , ( 2, 117 )
                            , pair3
                            ]
                        )
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.insert 3 117
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , ( 3, 117 )
                            ]
                        )
        ]


removeTest : Test
removeTest =
    describe "remove"
        [ test "not present" <|
            \_ ->
                pairs
                    |> DictList.remove 17
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            , pair3
                            ]
                        )
        , test "first" <|
            \_ ->
                pairs
                    |> DictList.remove 1
                    |> Expect.equal
                        (DictList.fromList
                            [ pair2
                            , pair3
                            ]
                        )
        , test "second" <|
            \_ ->
                pairs
                    |> DictList.remove 2
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair3
                            ]
                        )
        , test "third" <|
            \_ ->
                pairs
                    |> DictList.remove 3
                    |> Expect.equal
                        (DictList.fromList
                            [ pair1
                            , pair2
                            ]
                        )
        ]
