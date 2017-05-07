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
