module Ext.Function exposing (..)

import List.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)


increment num =
    num + 1


decrement num =
    num - 1


apply a f =
    f a


applyWith f1 f2 model =
    f2 (f1 model) model


apply2With ( f1, f2 ) f model =
    apply3Uncurry ( f1, f2, identity ) f model


applyMaybeWith f1 f2 model =
    f1 model ?|> f2 # model ?= model


apply2Uncurry f1 f2 model =
    (uncurry f2) (apply2 f1 model)


apply3Uncurry f1 f2 model =
    (uncurry3 f2) (apply3 f1 model)


ifElse : (a -> Bool) -> (a -> b) -> (a -> b) -> a -> b
ifElse pred onTrue onFalse value =
    if pred value then
        onTrue value
    else
        onFalse value


whenBool bool =
    when (always bool)


when : (a -> Bool) -> (a -> a) -> a -> a
when pred onTrue value =
    ifElse pred onTrue (\_ -> value) value


unless : (a -> Bool) -> (a -> a) -> a -> a
unless pred =
    when (pred >> not)


reject pred xs =
    let
        conditionalCons front back =
            if pred front then
                back
            else
                front :: back
    in
        List.foldr conditionalCons [] xs


gt =
    (>)


lt =
    (<)


lte =
    (<=)


isLT =
    flip lt


isLTE =
    flip lte


or =
    (||)


and =
    (&&)


equals =
    (==)


notEquals =
    (/=)


allPass predicates model =
    List.all (apply model) predicates


anyPass predicates model =
    List.any (apply model) predicates


subtract =
    (-)


andThenSubtract =
    flip subtract


add =
    (+)
