module Test.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import String.Extra as String


createItems model =
    model.list .|> createItem model.selectedIdx


createItem selectedIdx idx =
    let
        tabIndexValue =
            if idx == selectedIdx then
                0
            else
                -1
    in
        li [ tabindex tabIndexValue ] [ idx |> toString >> String.append "item no: " >> text ]


init =
    ul [] (createItems createModel)


createModel =
    { list = List.range 0 10
    , selectedIdx = 0
    }


type alias Model =
    { list : List Int
    , selectedIdx : Int
    }
