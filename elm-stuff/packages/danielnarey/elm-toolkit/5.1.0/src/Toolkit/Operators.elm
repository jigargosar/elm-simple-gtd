module Toolkit.Operators exposing
  ( (|++), (|::)
  , (:|++), (:|::)
  , (#), (||>)
  , (.|>), (:|>)
  , (..|>), (@@|>)
  , (?=), (!=)
  , (?|>), (!|>)
  , (?+>), (!+>)
  )

{-|

## A set of custom infix operators for maintaining a consistent, unidirectional coding style when working with lists, `Maybe` and `Result` values, and functions that take multiple arguments

At some point after I started working in Elm, it became clear to me that
debugging, refactoring, and extending existing code would be a lot easier if
I conventionalized some stylistic choices so that code blocks would always be
formatted in a consistent way. The built-in functional operators in Elm allow
for a lot of flexibility in how code is written, but some of that flexibility
has to be reined in if we want to emphasize readability as a virtue in
functional programming.

In constructing some stylistic rules for my own code, the principle I decided to
prioritize is what I call __unidirectionality__: *the idea that a programmer
should be able to readily discern the sequence of function calls in a code block
by visually scanning the code from top to bottom, and then from left to right*.

According to this principle, the "data" — that is, the value or set of values
that the function is called *on* — should always appear at the top of the code
block, with functions called on the data appearing on subsequent lines. A
nested series of function calls can appear on one line, but more complex code
chunks should be broken up into self-contained functions using `let..in`
statements. Nested list brackets and complex code chunks within list brackets
should generally be avoided.

With the above principle, the `|>` operator is used very liberally, the `>>`
operator is used only in rare cases, and there is no use case for "reverse"
(right-to-left) functional operators. In addition to liberal use of the `|>`
operator, I have found use cases for a small set of custom operators that help
to maintain consistent visual formatting and enhance readability of code blocks
by reducing clutter. I have included them here in one module so that I can
easily import them into other projects.


# Appending Things
@docs (|++), (|::), (:|++), (:|::)

# Function Application
@docs (#), (||>)

## with Lists
@docs (.|>), (:|>)

## with Tuples
@docs (..|>), (@@|>)

# Error Handling with `Maybe` and `Result` Values
@docs (?=), (!=), (?|>), (!|>), (?+>), (!+>)

-}


--APPENDING THINGS

{-| Append the RHS to the end of the LHS; equivalent to `++`, but
left-associative with precedence set to `0` (same as `|>`)

    ("ba" |> String.reverse) ++ "c"       --> "abc"
    "ba" |> String.reverse ++ "c"         --> ERROR
    "ba" |> String.reverse |++ "c"        --> "abc"

-}
(|++) : appendable -> appendable -> appendable
(|++) a b =
  a ++ b

infixl 0 |++


{-| Append the item on the RHS to the end of the list on the LHS

    [1] |:: 2         --> [1,2]
    [1] |:: 2 |:: 3   --> [1,2,3]
-}
(|::) : List a -> a -> List a
(|::) list a =
  list ++ [ a ]

infixl 0 |::


{-| Wrap LHS in a list, then append RHS list to it; equivalent to `::`, but
left-associative with precedence set to `0` (same as `|>`)

    ("a" ++ "b") :: ["cd","ef"]   --> ["ab","cd","ef"]
    "a" ++ "b" :: ["cd","ef"]     --> ERROR
    "a" ++ "b" :|++ ["cd","ef"]   --> ["ab","cd","ef"]

-}
(:|++) : a -> List a -> List a
(:|++) a list =
   a :: list

infixl 0 :|++


{-| Wrap LHS in a list, then append the item on RHS to the list

    1 :|:: 2    --> [1,2]

-}
(:|::) : a -> a -> List a
(:|::) a b =
  [a, b]

infixl 0 :|::


--FUNCTION APPLICATION

{-| An operator for
[`flip`](http://package.elm-lang.org/packages/elm-lang/core/5.0.0/Basics#flip).
Think of the `#` symbol as appearing where the missing argument would go.

    4 |> (/) 2        --> 0.5
    4 |> flip (/) 2   --> 2
    4 |> (/) # 2      --> 2


-}
(#) : (a -> b -> c) -> b -> (a -> c)
(#) f b =
  flip f b

infixl 9 #

{-| Forward function application with precedence set to 9. Allows you to avoid
parentheses when you want the argument to appear before the function name in an
inline expression.

    1 ||> toString ++ 2 ||> toString    --> "12"
-}
(||>) : a -> (a -> b) -> b
(||>) a f =
  f a

infixl 9 ||>


{-| Forward operator for List.map

    [1,4,9] .|> sqrt    --> [1,2,3]
-}
(.|>) : List a -> (a -> b) -> List b
(.|>) list f =
  List.map f list

infixl 0 .|>


{-| Wrap LHS in a list, then apply RHS function

    1 :|> List.head   --> Just 1
-}
(:|>) : a -> (List a -> b) -> b
(:|>) a f =
  f [ a ]

infixl 0 :|>


{-| Forward operator for
[map2Tuple](http://package.elm-lang.org/packages/danielnarey/elm-toolkit/latest/Toolkit-Helpers#map2Tuple)

    (1,2) ..|> (+) 1    --> (2,3)
-}
(..|>) : (a, a) -> (a -> b) -> (b, b)
(..|>) (a1, a2) f =
  (f a1, f a2)

infixl 0 ..|>


{-| Forward operator for
[`uncurry`](http://package.elm-lang.org/packages/elm-lang/core/latest/Basics#uncurry)
with 2 parameters

    (1,2) @@|> (+)    --> 3
-}
(@@|>) : (a, b) -> (a -> b -> c) -> c
(@@|>) params f =
  uncurry f params

infixl 0 @@|>


-- ERROR HANDLING

{-| Forward operator for Maybe.withDefault

    Just 42 ?= 100    --> 42
    Nothing ?= 100    --> 100
-}
(?=) : Maybe a -> a -> a
(?=) maybeValue defaultValue =
  Maybe.withDefault defaultValue maybeValue

infixl 0 ?=


{-| Forward operator for Result.withDefault

    String.toInt "123" != 0    --> 123
    String.toInt "abc" != 0    --> 0
-}
(!=) : Result x a -> a -> a
(!=) resultValue defaultValue =
  Result.withDefault defaultValue resultValue

infixl 0 !=


{-| Forward operator for Maybe.map

    Just 9 ?|> sqrt     --> Just 3
    Nothing ?|> sqrt    --> Nothing

-}
(?|>) : Maybe a -> (a -> b) -> Maybe b
(?|>) maybeValue f =
  Maybe.map f maybeValue

infixl 0 ?|>


{-| Forward operator for Result.map

    Ok 4.0 !|> sqrt             --> Ok 2.0
    Err "bad input" !|> sqrt    --> Err "bad input"

-}
(!|>) : Result x a -> (a -> value) -> Result x value
(!|>) resultValue f =
  Result.map f resultValue

infixl 0 !|>


{-| Forward operator for Maybe.andThen

    List.head [1] ?+> always Nothing    --> Nothing
-}
(?+>) : Maybe a -> (a -> Maybe b) -> Maybe b
(?+>) firstResult nextFunction =
  firstResult
    |> Maybe.andThen nextFunction

infixl 0 ?+>


{-| Forward operator for Result.andThen

    String.toInt "1" !+> always (Err "ERROR")    --> Err "ERROR"
-}
(!+>) : Result x a -> (a -> Result x b) -> Result x b
(!+>) firstResult nextFunction =
  firstResult
    |> Result.andThen nextFunction

infixl 0 !+>
