module ListSelection exposing (..)

import Ext.List as List
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


setSelectedIndex_ selectedIndex model =
    { model | selectedIndex = selectedIndex }


setList_ list model =
    { model | list = list }


empty =
    Model [] 0


getMaybeSelected { list, selectedIndex } =
    list |> List.getAt selectedIndex


selectItem : a -> ModelF a
selectItem item ({ list, selectedIndex } as model) =
    list |> List.findIndex (equals item) ?|> setSelectedIndex_ # model ?= model


updateList list model =
    getMaybeSelected model
        |> (selectMaybeItem # (setList_ list model))


selectMaybeItem maybeItem model =
    maybeItem
        ?|> (selectItem # model)
        ?= model


clampAndSetSelectedIndex index model =
    List.clampIndex index model.list |> setSelectedIndex_ # model


selectNext : ModelF a
selectNext =
    updateAndClampSelectedIndex increment


selectPrev : ModelF a
selectPrev =
    updateAndClampSelectedIndex decrement


updateAndClampSelectedIndex : (Int -> Int) -> ModelF a
updateAndClampSelectedIndex fn model =
    fn model.selectedIndex |> clampAndSetSelectedIndex # model
