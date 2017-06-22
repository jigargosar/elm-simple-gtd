module Tests exposing (..)

import Test exposing (..)
import Expect
import String
import ParseInt exposing (..)


all : Test
all =
    concat [ parseTests, genTests ]


isErr : Result e a -> Bool
isErr r =
    case r of
        Err _ ->
            True

        Ok _ ->
            False


expectErr : Result e b -> Expect.Expectation
expectErr result =
    Expect.equal True (isErr result)


parseTests : Test
parseTests =
    describe "parsing"
        [ test "decimal" <|
            \() -> Expect.equal (Ok 314159) (parseInt "314159")
        , test "simple oct" <|
            \() -> Expect.equal (Ok 15) (parseIntOct "17")
        , test "hex" <|
            \() -> Expect.equal (Ok 2748) (parseIntHex "abc")
        , test "hex 2" <|
            \() -> Expect.equal (Ok 291) (parseIntHex "123")
        , test "hex 3" <|
            \() -> Expect.equal (Ok 3735928559) (parseIntHex "DEADBEEF")
        , test "base 32" <|
            \() -> Expect.equal (Ok 32767) (parseIntRadix 32 "VVV")
        , test "base 36" <|
            \() -> Expect.equal (Ok 1295) (parseIntRadix 36 "ZZ")
        , test "empty string" <|
            \() -> Expect.equal (Ok 0) (parseInt "")
        , test "ignore leading zeroes" <|
            \() -> Expect.equal (Ok 549) (parseInt "00549")
        , test "oct out of range" <|
            \() -> expectErr <| (parseIntRadix 8 "8")
        , test "nonnumeric string, base 10" <|
            \() -> expectErr <| (parseInt "foobar")
        , test "0x prefix is invalid" <|
            \() -> expectErr <| (parseIntRadix 16 "0xdeadbeef")
        , test "invalid character" <|
            \() -> expectErr <| parseInt "*&^*&^*y"
        , test "invalid radix" <|
            \() -> expectErr <| parseIntRadix 37 "90210"
        , test "int from char" <|
            \() -> Expect.equal (Ok 7) (intFromChar 10 '7')
        , test "char from int" <|
            \() -> Expect.equal '7' (charFromInt 7)
        , test "hex char from int" <|
            \() -> Expect.equal 'C' (charFromInt 12)
        ]


genTests : Test
genTests =
    describe "generators"
        [ test "gen hex" <| \() -> Expect.equal (Ok "BEEF") (toRadix 16 48879)
        , test "gen dec" <| \() -> Expect.equal (Ok "314159") (toRadix 10 314159)
        , test "gen binary" <| \() -> Expect.equal (Ok "100000") (toRadix 2 (2 ^ 5))
        , test "gen oct" <| \() -> Expect.equal (Ok "30071") (toRadix 8 12345)
        , test "test zero" <| \() -> Expect.equal (Ok "0") (toRadix 10 0)
        , test "test negative" <| \() -> Expect.equal (Ok "-123") (toRadix 10 -123)
        , test "gen bad radix" <| \() -> expectErr <| toRadix 1 12345
        , test "gen bad radix" <| \() -> expectErr <| toRadix 37 12345
          --    , test "bad radix unsafe" <| \() -> Expect.equal "asplode" <| toRadix' 37 36
        , test "to hex" <| \() -> Expect.equal "BEEF" (toHex 48879)
        , test "to oct" <| \() -> Expect.equal "153213" (toOct 54923)
        ]
