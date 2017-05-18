module Function exposing (..)

{-|
## Function arrow as a type
@docs Arrow

## Compose a two parameter function with a single parameter function
@docs (>>>), (<<<)

## Compose a three parameter function with a single parameter function
@docs (>>>>), (<<<<)

## Function properties
@docs map, map2, map3, map4, map5, map6, andMap, andThen, singleton, on

## Reorder
@docs swirlr, swirll, flip3
-}

{-|
Making `->` into a type makes reading it much easier,
to read the effects when treating functions as a data structure.
-}
type alias Arrow a b = a -> b

{-|
```elm
(\x y -> foo x y |> bar)
-- becomes
foo >>> bar
```
-}
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

{-|-}
map : (a -> b) -> Arrow x a -> Arrow x b
map = (<<)

{-|-}
map2 : (a -> b -> c) -> Arrow x a -> Arrow x b -> Arrow x c
map2 f a b =
  map f a
  |> andMap b

{-|-}
map3 : (a -> b -> c -> d) -> Arrow x a -> Arrow x b -> Arrow x c -> Arrow x d
map3 f a b c =
  map f a
  |> andMap b
  |> andMap c

{-|-}
map4 : (a -> b -> c -> d -> e) -> Arrow x a -> Arrow x b -> Arrow x c -> Arrow x d -> Arrow x e
map4 f a b c d =
  map f a
  |> andMap b
  |> andMap c
  |> andMap d

{-|-}
map5 : (a -> b -> c -> d -> e -> f) -> Arrow x a -> Arrow x b -> Arrow x c -> Arrow x d -> Arrow x e -> Arrow x f
map5 f a b c d e =
    map f a
    |> andMap b
    |> andMap c
    |> andMap d
    |> andMap e

{-|-}
map6 : (a -> b -> c -> d -> e -> f -> g) -> Arrow x a -> Arrow x b -> Arrow x c -> Arrow x d -> Arrow x e -> Arrow x f -> Arrow x g
map6 f a b c d e g =
    map f a
    |> andMap b
    |> andMap c
    |> andMap d
    |> andMap e
    |> andMap g

{-| Make a function that will call two functions on the same value and subsequently combine them.

Useful for longer chains, see the following examples:

    f = (,) `map` sqrt `andMap` (\x -> x ^ 2)
    f 4 -- (2, 16)

    g = (,,) `map` toString `andMap` ((+) 1) `andMap` (\x -> x % 5)
    g 12 -- ("12",13,2)
-}
andMap : Arrow x a -> Arrow x (a -> b) -> Arrow x b
andMap f ff = \x -> ff x (f x)

{-|
The functions are Monads and so should have an `andThen`.
-}
andThen : (a -> Arrow x b) -> Arrow x a -> Arrow x b
andThen k f = \x -> k (f x) x

{-|
The functions are Monads and so should have a `singleton`.
-}
singleton : a -> Arrow x a
singleton = always

{-|
```elm
sortBy (compare `on` fst)
```
-}
on : (b -> b -> c) -> (a -> b) -> a -> a -> c
on g f = \x y -> g (f x) (f y)

{-|
```elm
foo = List.foldr (\a b -> bar a ++ baz b) 0 xs
--becomes
foo = swirlr List.foldr xs (\a b -> bar a ++ baz b) 0
```
-}
swirlr : (a -> b -> c -> d) -> c -> a -> b -> d
swirlr f c a b = f a b c

{-|
```elm
foo = List.foldr (\a b -> bar a ++ baz b) 0 xs
--becomes
foo = swirll List.foldr 0 xs
  <| \a b -> bar a ++ baz b
```
-}
swirll : (a -> b -> c -> d) -> b -> c -> a -> d
swirll f b c a = f a b c

{-|-}
flip3 : (a -> b -> c -> d) -> c -> b -> a -> d
flip3 f c b a = f a b c
