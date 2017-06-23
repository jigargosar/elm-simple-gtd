module Function.Pro exposing (..)

{-|
Basic Pro Functor utilities for working on functions

## Functors
@docs mapBefore, mapAfter, mapBoth

## Tuples
Tuples are ultimately AND on the type level
@docs first, second, sproodle

## Either
Eithers are ultimately XOR on the type level
@docs mapWithLeft, mapWithRight
-}

import Function exposing (Arrow, map)
import Either exposing (Either(..))


{-| Map on the co-domain -}
mapAfter : (a -> b) -> Arrow x a -> Arrow x b
mapAfter = map

{-| Map on the domain -}
mapBefore : (b -> a) -> Arrow a x -> Arrow b x
mapBefore g f = g >> f

{-| Map both sides of a function -}
mapBoth : (a -> b) -> (c -> d) -> Arrow b c -> Arrow a d
mapBoth f g x = g << x << f

{-| Slip in a value on the right hand side of a tuple -}
first : Arrow a b -> Arrow (a, x) (b, x)
first f (a, x) = (f a, x)

{-| Slip in a value on the left hand side of a tuple -}
second : Arrow a b -> Arrow (x, a) (x, b)
second f (x, a) = (x, f a)

{-| I think I know exactly what I mean -}
sproodle : Arrow a (b -> c) -> Arrow (a, b) c
sproodle =
  mapAfter (uncurry (<|)) << first

{-| -}
mapWithRight : Arrow a b -> Arrow (Either x a) (Either x b)
mapWithRight = Either.map

{-| -}
mapWithLeft : Arrow a b -> Arrow (Either a x) (Either b x)
mapWithLeft = Either.mapLeft
