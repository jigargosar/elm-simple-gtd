module RandomIdGenerator exposing (..)

import Random.Pcg as Random exposing (Generator, Seed)
import Char
import Time exposing (Time)


lowercaseLetter =
    Random.map (\n -> Char.fromCode (n + 97)) (Random.int 0 25)


uppercaseLetter =
    Random.map (\n -> Char.fromCode (n + 65)) (Random.int 0 25)


digit =
    Random.map (\n -> Char.fromCode (n + 48)) (Random.int 0 9)


alphaNumericChar =
    Random.frequency [ ( 26, lowercaseLetter ), ( 26, uppercaseLetter ), ( 10, digit ) ]


idGen : Generator String
idGen =
    Random.map (String.fromList) (Random.list 64 alphaNumericChar)


seedFromTime : Time -> Seed
seedFromTime =
    round >> Random.initialSeed
