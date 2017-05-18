module Tuple3 exposing (..)

{-|
# Getters
@docs first, second, third, tail, init

# Maps
@docs map, mapFirst, mapSecond, mapThird, mapEach, mapAll

# Swap
@docs swirlr, swirll

# Sorting
@docs sort, sortBy, sortWith

# Transform
@docs toList
-}

import Tuple2


{-| -}
first : ( a, b, c ) -> a
first ( a, _, _ ) =
    a


{-| -}
second : ( a, b, c ) -> b
second ( _, b, _ ) =
    b


{-| -}
third : ( a, b, c ) -> c
third ( _, _, c ) =
    c


{-| -}
tail : ( a, b, c ) -> ( b, c )
tail ( _, b, c ) =
    ( b, c )


{-| -}
init : ( a, b, c ) -> ( a, b )
init ( a, b, _ ) =
    ( a, b )


{-| -}
mapFirst : (a -> x) -> ( a, b, c ) -> ( x, b, c )
mapFirst f ( a, c, d ) =
    ( f a, c, d )


{-| -}
mapSecond : (b -> x) -> ( a, b, c ) -> ( a, x, c )
mapSecond f ( a, b, c ) =
    ( a, f b, c )


{-| -}
mapThird : (c -> x) -> ( a, b, c ) -> ( a, b, x )
mapThird f ( a, b, c ) =
    ( a, b, f c )


{-| -}
mapEach : (a -> x) -> (b -> x_) -> (c -> x__) -> ( a, b, c ) -> ( x, x_, x__ )
mapEach f f_ f__ ( a, b, c ) =
    ( f a, f_ b, f__ c )


{-| -}
mapAll : (a -> b) -> ( a, a, a ) -> ( b, b, b )
mapAll f ( a, a_, a__ ) =
    ( f a, f a_, f a__ )


{-| -}
map : (c -> x) -> ( a, b, c ) -> ( a, b, x )
map =
    mapThird


{-| -}
sort : ( comparable, comparable, comparable ) -> ( comparable, comparable, comparable )
sort =
    sortWith compare


{-| -}
sortBy : (a -> comparable) -> ( a, a, a ) -> ( a, a, a )
sortBy conv =
    sortWith (\x y -> compare (conv x) (conv y))


{-| -}
sortWith : (a -> a -> Order) -> ( a, a, a ) -> ( a, a, a )
sortWith cmp ( a, b, c ) =
    let
        goesBefore x y =
            not <| cmp x y == GT

        ( a_, b_ ) =
            Tuple2.sortWith cmp ( a, b )
    in
        if goesBefore c a_ then
            ( c, a_, b_ )
        else if goesBefore c b_ then
            ( a_, c, b_ )
        else
            ( a_, b_, c )


{-| -}
swirlr : ( a, b, c ) -> ( b, c, a )
swirlr ( a, b, c ) =
    ( b, c, a )


{-| -}
swirll : ( a, b, c ) -> ( c, a, b )
swirll ( a, b, c ) =
    ( c, a, b )


{-| -}
toList : ( a, a, a ) -> List a
toList ( a, b, c ) =
    [ a, b, c ]
