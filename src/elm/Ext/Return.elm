module Ext.Return exposing (..)

import Maybe.Extra as Maybe
import Return exposing (Return, ReturnF)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


maybeTransformWith :
    (a -> Maybe x)
    -> (x -> ReturnF msg a)
    -> ReturnF msg a
maybeTransformWith f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> apply (Return.singleton m)
        )


transformWith :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
transformWith f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) (Return.singleton m)
        )


with f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) m
        )


maybeWith f1 f2 =
    Return.andThen
        (\m ->
            (f2 (f1 m)) m ?= Return.singleton m
        )


mapModelWith f1 f2 =
    Return.map
        (\m ->
            (f2 (f1 m)) m
        )
