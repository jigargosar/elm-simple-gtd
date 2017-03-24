module FunctionExtra.Operators exposing (..)

(>>>) : (a -> b -> c) -> (c -> d) -> a -> b -> d
(>>>) ff f x y = ff x y |> f

{-|
```elm
(\x y -> bar <| foo x y)
-- becomes
bar <<< foo
```
-}
(<<<) : (c -> d) -> (a -> b -> c) -> a -> b -> d
(<<<) = flip (>>>)

{-|
```elm
(\x y z -> foo x y z |> bar)
-- becomes
foo >>>> bar
```
-}
(>>>>) : (a -> b -> c -> d) -> (d -> e) -> a -> b -> c -> e
(>>>>) fff f x y z = fff x y z |> f

{-|
```elm
(\x y z -> bar <| foo x y z)
-- becomes
bar <<<< foo
```
-}
(<<<<) : (d -> e) -> (a -> b -> c -> d) -> a -> b -> c -> e
(<<<<) = flip (>>>>)

