module Tuple4 exposing (..)

{-|
# Getters
@docs first, second, third, fourth, tail, init

# Maps
@docs map, mapFirst, mapSecond, mapThird, mapFourth, mapEach, mapAll

# Swap
@docs swirlr, swirll

# Sorting
@docs sort, sortBy, sortWith

# Transform
@docs toList
-}

import Tuple3


{-| -}
first : ( a, b, c, d ) -> a
first ( a, _, _, _ ) =
    a


{-| -}
second : ( a, b, c, d ) -> b
second ( _, b, _, _ ) =
    b


{-| -}
third : ( a, b, c, d ) -> c
third ( _, _, c, _ ) =
    c


{-| -}
fourth : ( a, b, c, d ) -> d
fourth ( _, _, _, d ) =
    d


{-| -}
tail : ( a, b, c, d ) -> ( b, c, d )
tail ( _, b, c, d ) =
    ( b, c, d )


{-| -}
init : ( a, b, c, d ) -> ( a, b, c )
init ( a, b, c, _ ) =
    ( a, b, c )


{-| -}
mapFirst : (a -> x) -> ( a, b, c, d ) -> ( x, b, c, d )
mapFirst f ( a, b, c, d ) =
    ( f a, b, c, d )


{-| -}
mapSecond : (b -> x) -> ( a, b, c, d ) -> ( a, x, c, d )
mapSecond f ( a, b, c, d ) =
    ( a, f b, c, d )


{-| -}
mapThird : (c -> x) -> ( a, b, c, d ) -> ( a, b, x, d )
mapThird f ( a, b, c, d ) =
    ( a, b, f c, d )


{-| -}
mapFourth : (d -> x) -> ( a, b, c, d ) -> ( a, b, c, x )
mapFourth f ( a, b, c, d ) =
    ( a, b, c, f d )


{-| -}
mapEach : (a -> x) -> (b -> x_) -> (c -> x__) -> (d -> x___) -> ( a, b, c, d ) -> ( x, x_, x__, x___ )
mapEach f f_ f__ ff ( a, b, c, d ) =
    ( f a, f_ b, f__ c, ff d )


{-| -}
mapAll : (a -> b) -> ( a, a, a, a ) -> ( b, b, b, b )
mapAll f ( a, a_, a__, aa ) =
    ( f a, f a_, f a__, f aa )


{-| -}
map : (d -> x) -> ( a, b, c, d ) -> ( a, b, c, x )
map =
    mapFourth


{-| -}
sort : ( comparable, comparable, comparable, comparable ) -> ( comparable, comparable, comparable, comparable )
sort =
    sortWith compare


{-| -}
sortBy : (a -> comparable) -> ( a, a, a, a ) -> ( a, a, a, a )
sortBy conv =
    sortWith (\x y -> compare (conv x) (conv y))


{-| -}
sortWith : (a -> a -> Order) -> ( a, a, a, a ) -> ( a, a, a, a )
sortWith cmp ( a, b, c, d ) =
    let
        goesBefore x y =
            not <| cmp x y == GT

        ( a_, b_, c_ ) =
            Tuple3.sortWith cmp ( a, b, c )
    in
        if goesBefore d a_ then
            ( d, a_, b_, c_ )
        else if goesBefore d b_ then
            ( a_, d, b_, c_ )
        else if goesBefore d c_ then
            ( a_, b_, d, c_ )
        else
            ( a_, b_, c_, d )


{-| -}
swirlr : ( a, b, c ) -> ( b, c, a )
swirlr ( a, b, c ) =
    ( b, c, a )


{-| -}
swirll : ( a, b, c ) -> ( c, a, b )
swirll ( a, b, c ) =
    ( c, a, b )


{-| -}
toList : ( a, a, a, a ) -> List a
toList ( a, b, c, d ) =
    [ a, b, c, d ]
