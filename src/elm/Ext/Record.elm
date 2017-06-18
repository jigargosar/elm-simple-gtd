module Ext.Record
    exposing
        ( field
        , bool
        , toggle
        , get
        , set
        , setIn
        , over
        , overT2
        , maybeOverT2
        , overReturn
        , maybeSet
        , maybeSetIn
        , maybeOver
        )

import Return
import Toolkit.Operators exposing (..)


type alias FieldModel small big =
    { get : big -> small, set : small -> big -> big }


type Field small big
    = Field (FieldModel small big)


type alias BoolField big =
    Field Bool big


field : (big -> small) -> (small -> big -> big) -> Field small big
field getter setter =
    Field { get = getter, set = setter }


bool : (big -> Bool) -> (Bool -> big -> big) -> Field Bool big
bool getter setter =
    Field { get = getter, set = setter }


toggle : BoolField big -> big -> big
toggle boolField big =
    over boolField (not) big


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


maybeOver field smallF big =
    smallF (get field big)
        ?|> setIn big field
        ?= big


setIn big field small =
    set field small big


overT2 field smallFT2 b =
    get field b
        |> smallFT2
        |> Tuple.mapSecond (setIn b field)


maybeOverT2 field smallFT2 b =
    get field b
        |> smallFT2
        ?|> Tuple.mapSecond (setIn b field)


overReturn : Field small big -> (small -> Return.Return msg small) -> big -> Return.Return msg big
overReturn field smallFT2 b =
    get field b
        |> smallFT2
        |> Tuple.mapFirst (setIn b field)
