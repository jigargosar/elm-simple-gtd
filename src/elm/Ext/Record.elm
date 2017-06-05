module Ext.Record exposing (init, get, set, over, setIn, overT2, maybeSet, maybeSetIn)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias FieldModel small big =
    { get : big -> small, set : small -> big -> big }


type Field small big
    = Field (FieldModel small big)


init : (big -> small) -> (small -> big -> big) -> Field small big
init getter setter =
    Field { get = getter, set = setter }


get (Field field) big =
    field.get big


set (Field field) small big =
    field.set small big


maybeSet field maybeSmall big =
    maybeSmall ?|> setIn big field ?= big


maybeSetIn big field maybeSmall =
    maybeSet field maybeSmall big


over field smallF big =
    setIn big field (smallF (get field big))


setIn big field small =
    set field small big


overT2 field smallFT2 b =
    get field b
        |> smallFT2
        |> Tuple.mapSecond (setIn b field)
