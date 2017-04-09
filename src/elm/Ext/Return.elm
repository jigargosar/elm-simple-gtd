module Ext.Return exposing (..)

import Maybe.Extra as Maybe
import Return exposing (Return, ReturnF)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function as F exposing (..)


withMaybe :
    (a -> Maybe x)
    -> (x -> ReturnF msg a)
    -> ReturnF msg a
withMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> F.apply (Return.singleton m)
        )


with :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
with f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) (Return.singleton m)
        )


mapModelWithMaybe f1 f2 =
    Return.map
        (\m ->
            f1 m ?|> f2 ?= m
        )


mapModelWith f1 f2 =
    Return.map
        (\m ->
            (f2 (f1 m)) m
        )


andThenApplyWith f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) m
        )


andThenApplyWithMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= m
        )


maybeEffect f =
    Return.effect_ (\m -> f m ?= Cmd.none)


apply =
    flip Return.andThen
