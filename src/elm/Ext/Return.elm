module Ext.Return exposing (..)

import Maybe.Extra as Maybe
import Return exposing (Return, ReturnF)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


transformModelTupleWith f =
    Return.andThen (\( x, m ) -> (f x) (Return.singleton m))


transformMaybeModelTupleWith f =
    transformModelTupleWith (Maybe.unwrap identity f)


maybeTransformWith :
    (a -> Maybe x)
    -> (x -> ReturnF msg a)
    -> ReturnF msg a
maybeTransformWith f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> apply (Return.singleton m)
        )


andThenMaybe f =
    Return.andThen (\m -> f m ?= Return.singleton m)


transformWithComplexImplementation :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
transformWithComplexImplementation f1 f2 =
    Return.map (apply2 ( f1, identity ))
        >> Return.andThen (\( x, m ) -> (f2 x) (Return.singleton m))


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
