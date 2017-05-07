module ListSelection exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model a =
    { list : List a
    , selectedIndex : Int
    }


type alias ModelF a =
    Model a -> Model a


empty =
    Model [] 0


getMaybeSelected { list, selectedIndex } =
    list |> List.getAt selectedIndex


selectItem : a -> ModelF a
selectItem item ({ list, selectedIndex } as model) =
    list |> List.findIndex (equals item) ?|> setSelectedIndex # model ?= model


setSelectedIndex selectedIndex model =
    { model | selectedIndex = selectedIndex }


setList list model =
    { model | list = list }


clampAndSetSelectedIndex index model =
    clampIndex index model |> setSelectedIndex # model


listLastIndex list =
    case list of
        [] ->
            0

        _ ->
            (List.length list) - 1


clampIndex : Int -> Model a -> Int
clampIndex index =
    .list >> listLastIndex >> clamp 0 # index


increment num =
    num + 1


decrement num =
    num - 1


selectNext : ModelF a
selectNext =
    updateAndClampSelectedIndex increment


selectPrev : ModelF a
selectPrev =
    updateAndClampSelectedIndex decrement


updateAndClampSelectedIndex : (Int -> Int) -> ModelF a
updateAndClampSelectedIndex fn model =
    fn model.selectedIndex |> clampAndSetSelectedIndex # model
