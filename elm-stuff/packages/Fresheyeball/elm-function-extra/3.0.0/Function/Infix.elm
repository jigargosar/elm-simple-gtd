module Function.Infix exposing (..)

{-|
Elm is getting less functional, here is some relief
@docs (<$>), (<*>), (>>=), (<.>)
-}

import Function
import Function.Pro as Function

-- infixl 4 <$>
{-| map as an infix, like normal -}
(<$>) : (a -> b) -> (x -> a) -> x -> b
(<$>) = (<<)

-- infixl 5 <*>
{-| apply as an infix, like normal -}
(<*>) : (x -> a -> b) -> (x -> a) -> x -> b
(<*>) = flip Function.andMap

-- infixl 1 >>=
{-| bind as an infix, like normal -}
(>>=) : (x -> a) -> (a -> x -> b) -> x -> b
(>>=) = flip Function.andThen

{-| Profunctor about, like a baby rabbit in a meadow -}
(<.>) : (a -> b) -> (c -> d) -> (b -> c) -> (a -> d)
(<.>) = Function.mapBoth
