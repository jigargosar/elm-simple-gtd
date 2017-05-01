module Test.View exposing (..)

import Ext.Keyboard exposing (onKeyDown)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import String.Extra as String


createItems model =
    model.list .|> createItem model.selectedIndex


createItem selectedIndex idx =
    let
        tabIndexValue =
            if idx == selectedIndex then
                0
            else
                -1
    in
        li [ tabindex tabIndexValue ] [ idx |> toString >> String.append "item no: " >> text ]


init selectedIndex =
    let
        viewModel =
            { list = List.range 0 10
            , selectedIndex = selectedIndex
            }
    in
        ul [ onKeyDown Msg.OnTestListKeyDown ] (createItems viewModel)


type alias ViewModel =
    { list : List Int
    , selectedIndex : Int
    }
