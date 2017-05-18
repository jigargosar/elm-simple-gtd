module Tuple2 exposing (..)

{-|

# Tuple definition
@docs (=>)

# Map
@docs map, mapFirst, mapSecond, mapEach, mapBoth

# Swap
@docs swap

# Sorting
@docs sort, sortBy, sortWith

# Transform
@docs toList

-}


{-| Define a double with infix operator. Primarily used, when defining a List
    with key-value Tuples.

    Dict.fromList
        [ 0 => 'a'
        , 1 => 'b'
        , 2 => 'c'
        ]
-}
(=>) : a -> b -> ( a, b )
(=>) a b =
    ( a, b )


{-| -}
mapFirst : (a -> x) -> ( a, b ) -> ( x, b )
mapFirst f ( a, b ) =
    ( f a, b )


{-| -}
mapSecond : (b -> x) -> ( a, b ) -> ( a, x )
mapSecond f ( c, a ) =
    ( c, f a )


{-| -}
mapEach : (a -> x) -> (b -> x_) -> ( a, b ) -> ( x, x_ )
mapEach f f_ ( a, c ) =
    ( f a, f_ c )


{-| -}
mapBoth : (a -> b) -> ( a, a ) -> ( b, b )
mapBoth f ( a, a_ ) =
    ( f a, f a_ )


{-| -}
map : (b -> x) -> ( a, b ) -> ( a, x )
map =
    mapSecond


{-| -}
swap : ( a, b ) -> ( b, a )
swap ( a, b ) =
    ( b, a )


{-| -}
sort : ( comparable, comparable ) -> ( comparable, comparable )
sort ( a, b ) =
    if a > b then
        ( b, a )
    else
        ( a, b )


{-| -}
sortBy : (a -> comparable) -> ( a, a ) -> ( a, a )
sortBy f ( a, b ) =
    if f a > f b then
        ( b, a )
    else
        ( a, b )


{-| -}
sortWith : (a -> a -> Order) -> ( a, a ) -> ( a, a )
sortWith cmp ( a, b ) =
    case cmp a b of
        GT ->
            ( b, a )

        _ ->
            ( a, b )


{-| -}
toList : ( a, a ) -> List a
toList ( a, b ) =
    [ a, b ]
