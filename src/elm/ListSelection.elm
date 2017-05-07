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
    List.clampIndex index model.list |> setSelectedIndex # model


selectNext : ModelF a
selectNext =
    updateAndClampSelectedIndex increment


selectPrev : ModelF a
selectPrev =
    updateAndClampSelectedIndex decrement


updateAndClampSelectedIndex : (Int -> Int) -> ModelF a
updateAndClampSelectedIndex fn model =
    fn model.selectedIndex |> clampAndSetSelectedIndex # model
