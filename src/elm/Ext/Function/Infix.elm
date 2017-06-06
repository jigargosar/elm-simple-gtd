module Ext.Function.Infix exposing (..)


(=>) =
    (,)
infixr 5 =>


(.#|>) =
    flip List.indexedMap
infixl 0 .#|>


(?>>) f1 f2 =
    f1 >> Maybe.map f2
infixl 9 ?>>


(>>?) f1 f2 =
    f1 >> Maybe.map f2
infixl 9 >>?


(>>?=) fn val =
    fn >> Maybe.withDefault val
infixl 9 >>?=


(>>?+) f1 f2 =
    f1 >> Maybe.andThen f2
infixl 9 >>?+


(>>>) : (a -> b -> c) -> (c -> d) -> a -> b -> d
(>>>) ff f x y =
    ff x y |> f


{-|

    (\x y -> bar <| foo x y)
    -- becomes
    bar <<< foo
-}
(<<<) : (c -> d) -> (a -> b -> c) -> a -> b -> d
(<<<) =
    flip (>>>)


{-|

    (\x y z -> foo x y z |> bar)
    -- becomes
    foo >>>> bar
-}
(>>>>) : (a -> b -> c -> d) -> (d -> e) -> a -> b -> c -> e
(>>>>) fff f x y z =
    fff x y z |> f


{-|

    (\x y z -> bar <| foo x y z)
    -- becomes
    bar <<<< foo
-}
(<<<<) : (d -> e) -> (a -> b -> c -> d) -> a -> b -> c -> e
(<<<<) =
    flip (>>>>)
