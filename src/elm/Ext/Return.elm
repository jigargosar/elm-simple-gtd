module Ext.Return exposing (..)

import Return exposing (Return)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


transformTupleWith f =
    Return.andThen (\( x, m ) -> (f x) (Return.singleton m))



--returnAndMapMaybe : (Model -> Maybe x) -> (x -> ReturnF) -> ReturnF


transformWithMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> apply (Return.singleton m)
        )


transformWith2 :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
transformWith2 f1 f2 =
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
