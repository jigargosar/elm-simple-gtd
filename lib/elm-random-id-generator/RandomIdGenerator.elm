module IdGen exposing (..)

import Random.Pcg as Rng
import Char


lowercaseLetter =
    Rng.map (\n -> Char.fromCode (n + 97)) (Rng.int 0 25)


uppercaseLetter =
    Rng.map (\n -> Char.fromCode (n + 65)) (Rng.int 0 25)


digit =
    Rng.map (\n -> Char.fromCode (n + 48)) (Rng.int 0 9)


alphaNumericChar =
    Rng.frequency [ ( 26, lowercaseLetter ), ( 26, uppercaseLetter ), ( 10, digit ) ]


idGen =
    Rng.step (Rng.list 64 alphaNumericChar)
        >> Tuple.mapFirst String.fromList
