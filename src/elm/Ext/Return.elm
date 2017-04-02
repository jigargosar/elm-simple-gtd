module Ext.Return exposing (..)

import Return exposing (Return)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


transformTupleWith f =
    Return.andThen (\( x, m ) -> (f x) (Return.singleton m))



--returnAndMapMaybe : (Model -> Maybe x) -> (x -> ReturnF) -> ReturnF


andMapMaybe f1 f2 =
    Return.andThen
        (\m ->
            f1 m ?|> f2 ?= identity |> (\rf -> Return.singleton m |> rf)
        )


transformWith :
    (a -> x)
    -> (x -> Return msg a -> Return msg b)
    -> Return msg a
    -> Return msg b
transformWith f1 f2 =
    Return.map (apply2 ( f1, identity ))
        >> Return.andThen (\( x, m ) -> (f2 x) (Return.singleton m))
