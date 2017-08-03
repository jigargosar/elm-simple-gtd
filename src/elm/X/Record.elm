module X.Record
    exposing
        ( FieldLens
        , bool
        , composeInnerOuterFieldLens
        , fieldLens
        , get
        , getAndMaybeApply
        , mapFieldValue
        , maybeOver
        , maybeOverT2
        , maybeSet
        , maybeSetIn
        , over
        , overM
        , overReturn
        , overReturnF
        , overReturnFMapCmd
        , overT2
        , set
        , setIn
        , toggle
        )

import Return
import Toolkit.Operators exposing (..)


type alias FieldLensModel small big =
    { get : big -> small, set : small -> big -> big }


type FieldLens small big
    = FieldLens (FieldLensModel small big)


type alias BoolField big =
    FieldLens Bool big


fieldLens : (big -> small) -> (small -> big -> big) -> FieldLens small big
fieldLens getter setter =
    FieldLens { get = getter, set = setter }


composeInnerOuterFieldLens : FieldLens s m -> FieldLens m b -> FieldLens s b
composeInnerOuterFieldLens s2mLens m2bLens =
    FieldLens
        { get = \big -> get m2bLens big |> get s2mLens
        , set = \small big -> over m2bLens (set s2mLens small) big
        }


bool : (big -> Bool) -> (Bool -> big -> big) -> FieldLens Bool big
bool getter setter =
    FieldLens { get = getter, set = setter }


toggle : BoolField big -> big -> big
toggle boolField big =
    over boolField not big


mapFieldValue fieldLens fn big =
    get fieldLens big |> fn


getAndMaybeApply fieldLens fn =
    mapFieldValue fieldLens (Maybe.map fn)


get (FieldLens field) big =
    field.get big


set (FieldLens field) small big =
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


overM field bigToSmall big =
    setIn big field (bigToSmall big)


maybeOverT2 field smallToReturn b =
    get field b
        |> smallToReturn
        ?|> Tuple.mapSecond (setIn b field)


overReturn : FieldLens small big -> (small -> Return.Return msg small) -> big -> Return.Return msg big
overReturn field smallToReturn b =
    get field b
        |> smallToReturn
        |> Tuple.mapFirst (setIn b field)


overReturnFMapCmd :
    FieldLens small big
    -> (msgS -> msgB)
    -> Return.ReturnF msgS small
    -> Return.ReturnF msgB big
overReturnFMapCmd field lift smallReturnF =
    Return.andThen
        (overReturn field (Return.singleton >> smallReturnF)
            >> Return.mapCmd lift
        )


overReturnF :
    FieldLens small big
    -> Return.ReturnF msg small
    -> Return.ReturnF msg big
overReturnF field smallReturnF =
    Return.andThen (overReturn field (Return.singleton >> smallReturnF))
