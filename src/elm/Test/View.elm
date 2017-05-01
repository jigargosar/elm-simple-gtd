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
        li
            [ tabindex tabIndexValue
            , onFocus << Msg.OnTestListItemFocus <| idx
            ]
            [ idx |> toString >> String.append "item no: " >> text ]


init model =
    div []
        [ div [] [ model.selectedIndex |> toString >> text ]
        , ul [ class "test-list", onKeyDown Msg.OnTestListKeyDown ] (createItems model)
        ]
