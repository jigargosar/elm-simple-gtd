module Main exposing (..)

import Array
import Check exposing (Claim, check, claim, that, is, for)
import Check.Producer as CI
import Check.Test exposing (evidenceToTest)
import Legacy.ElmTest as ElmTest exposing (Test, Assertion, assert, assertEqual, test, suite, runSuiteHtml)
import Lazy.List exposing (empty, (:::))
import ParseInt exposing (..)
import Random exposing (initialSeed)
import Random.Char
import Random.String
import Shrink exposing (Shrinker)
import String


isErr : Result e a -> Bool
isErr r =
    case r of
        Err _ ->
            True

        Ok _ ->
            False


assertErr : Result a b -> Assertion
assertErr =
    assert << isErr


tests : Test
tests =
    suite "basic"
        [ test "decimal" <| assertEqual (Ok 314159) (parseInt "314159")
        , test "simple oct" (assertEqual (Ok 15) (parseIntOct "17"))
        , test "hex" (assertEqual (Ok 2748) (parseIntHex "abc"))
        , test "hex 2" <| assertEqual (Ok 291) (parseIntHex "123")
        , test "hex 3" <| assertEqual (Ok 3735928559) (parseIntHex "DEADBEEF")
        , test "base 32" <| assertEqual (Ok 32767) (parseIntRadix 32 "VVV")
        , test "base 36" <| assertEqual (Ok 1295) (parseIntRadix 36 "ZZ")
        , test "empty string" <| assertEqual (Ok 0) (parseInt "")
        , test "ignore leading zeroes" <| assertEqual (Ok 549) (parseInt "00549")
        , test "oct out of range" <| assert <| isErr (parseIntRadix 8 "8")
        , test "nonnumeric string, base 10" <| assert <| isErr (parseInt "foobar")
        , test "0x prefix is invalid" <| assert <| isErr (parseIntRadix 16 "0xdeadbeef")
        , test "invalid character" <| assertErr <| parseInt "*&^*&^*y"
        , test "invalid radix" <| assertErr <| parseIntRadix 37 "90210"
        , test "int from char" <| assertEqual (Ok 7) (intFromChar 10 '7')
        , test "char from int" <| assertEqual '7' (charFromInt 7)
        , test "hex char from int" <| assertEqual 'C' (charFromInt 12)
        ]


checkSuite : Test
checkSuite =
    suite "checks" [ testMatchesToInt, hexTest, hexTest2 ]


genSuite : Test
genSuite =
    suite "generator"
        [ test "gen hex" <| assertEqual (Ok "BEEF") (toRadix 16 48879)
        , test "gen dec" <| assertEqual (Ok "314159") (toRadix 10 314159)
        , test "gen binary" <| assertEqual (Ok "100000") (toRadix 2 (2 ^ 5))
        , test "gen oct" <| assertEqual (Ok "30071") (toRadix 8 12345)
        , test "test zero" <| assertEqual (Ok "0") (toRadix 10 0)
        , test "test negative" <| assertEqual (Ok "-123") (toRadix 10 -123)
        , test "gen bad radix" <| assertErr <| toRadix 1 12345
        , test "gen bad radix" <| assertErr <| toRadix 37 12345
          --    , test "bad radix unsafe" <| assertEqual "asplode" <| toRadix' 37 36
        , test "to hex" <| assertEqual "BEEF" (toHex 48879)
        , test "to oct" <| assertEqual "153213" (toOct 54923)
        ]


canonResult : Result ParseInt.Error a -> Result String a
canonResult r =
    case r of
        Ok i ->
            Ok i

        Err m ->
            Err (toString m)


testMatchesToInt : Test
testMatchesToInt =
    claim "Matches results of String.toInt"
        `that` (parseInt >> canonResult)
        `is` String.toInt
        `for` stringInvestigator
        |> check 100 (initialSeed 99)
        |> evidenceToTest


testMatchesToString : Test
testMatchesToString =
    claim "toRadix 10 matches results to toString"
        `that` (toRadix 10 >> canonResult)
        `is` (Ok << toString)
        `for` (CI.rangeInt Random.minInt Random.maxInt)
        |> check 100 (initialSeed 134)
        |> evidenceToTest


{-| Convert i to string with given radix, then back again to int.
-}
roundTrip : ( Int, Int ) -> Result Error Int
roundTrip ( radix, i ) =
    toRadix radix i |> Result.withDefault "" >> parseIntRadix radix


testCrossCheck : Test
testCrossCheck =
    claim "parseIntRadix inverts toRadix for non-negative Ints"
        `that` roundTrip
        `is` (Ok << snd)
        `for` (CI.tuple
                ( radixInvestigator
                , CI.rangeInt 0 Random.maxInt
                )
              )
        |> check 100 (initialSeed 99)
        |> evidenceToTest


{-| Investigate radix values. Based on CI.rangeInt but shrinks to 2 not 0.
-}
radixInvestigator : CI.Producer Int
radixInvestigator =
    { generator = (CI.rangeInt 2 36 |> .generator)
    , shrinker = (Shrink.atLeastInt 2)
    }


{-| Integer division that handles large numerators (mostly) correctly.  See
<https://github.com/elm-lang/core/issues/92>. The `toFloat` conversion can lose
precision and cause the result to be off as well.
-}
(//) : Int -> Int -> Int
(//) x y =
    floor (Basics.toFloat x / Basics.toFloat y)


hexClaim : Claim
hexClaim =
    claim "Hex conversion, dropping rightmost char results in dividing by 16"
        `that` (String.dropRight 1 >> parseIntRadix 16)
        `is` (parseIntRadix 16 >> Result.map (\i -> i // 16))
        `for` hexStringInvestigator


hexTest : Test
hexTest =
    check 100 (initialSeed 88) hexClaim
        |> evidenceToTest


hexTest2 : Test
hexTest2 =
    claim "Hex conversion, adding '0' to right results in multiplying by 16"
        `that` (parseIntRadix 16 >> Result.map (\i -> i * 16))
        `is` ((\s -> s ++ "0") >> parseIntRadix 16)
        `for` hexStringInvestigator
        |> check 100 (initialSeed 88)
        |> evidenceToTest


randomDigitChar : Random.Generator Char
randomDigitChar =
    Random.Char.char 48 57


randomHexChar : Random.Generator Char
randomHexChar =
    let
        hexChars =
            Array.fromList [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' ]
    in
        Random.map (\i -> Array.get i hexChars |> Maybe.withDefault 'X') (Random.int 0 15)


{-| Shrink by successively removing the head of the string. Do not include empty string.
-}
shrinker : Shrink.Shrinker String
shrinker s =
    case String.uncons s of
        Nothing ->
            empty

        Just ( _, rest ) ->
            if rest == "" then
                empty
            else
                rest ::: shrinker rest


{-| Generate random digit strings. Limit to 16 chars to keep full precision in javascript.
-}
stringInvestigator : CI.Producer String
stringInvestigator =
    { generator = (Random.String.rangeLengthString 1 16 randomDigitChar)
    , shrinker = shrinker
    }


{-| Generate strings containing random hexidecimal characters.  Since javascript
 loses precision for numbers over 2 ^ 54 (40000000000000 in hex) we limit the
 strings to 13 chars long to stay just under that.
-}
hexStringInvestigator : CI.Producer String
hexStringInvestigator =
    { generator = (Random.String.rangeLengthString 1 13 randomHexChar)
    , shrinker = shrinker
    }


main : Program Never
main =
    runSuiteHtml
        <| suite "all"
            [ tests
            , checkSuite
            , testMatchesToString
            , testCrossCheck
            , genSuite
            ]
