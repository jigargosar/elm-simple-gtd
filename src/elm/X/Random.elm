module X.Random exposing (..)

import Char
import Random.Pcg as Random exposing (Generator, Seed)
import Time exposing (Time)


lowercaseLetter =
    Random.map (\n -> Char.fromCode (n + 97)) (Random.int 0 25)


uppercaseLetter =
    Random.map (\n -> Char.fromCode (n + 65)) (Random.int 0 25)


digit =
    Random.map (\n -> Char.fromCode (n + 48)) (Random.int 0 9)


alphaNumericChar =
    Random.frequency [ ( 26, lowercaseLetter ), ( 26, uppercaseLetter ), ( 10, digit ) ]


idGenerator : Generator String
idGenerator =
    Random.map String.fromList (Random.list 64 alphaNumericChar)


seedFromTime : Time -> Seed
seedFromTime =
    round >> Random.initialSeed


mapWithIdGenerator f =
    Random.map f idGenerator


mapWithIndependentSeed f =
    Random.map f Random.independentSeed
