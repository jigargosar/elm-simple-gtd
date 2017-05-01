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
        isFocused =
            idx == selectedIndex

        tabIndexValue =
            if isFocused then
                0
            else
                -1
    in
        li
            [ tabindex tabIndexValue
            , classList [ "is-focused" => isFocused ]
            , idx |> Msg.OnTestListItemFocus >> onFocus
            ]
            [ idx |> toString >> String.append "item no: " >> text ]


init model =
    div []
        [ div [] [ model.selectedIndex |> toString >> text ]
        , div [ class "_big-dialog" ] [ h1 [] [ text "big-dialog" ] ]
        , ul [ class "focusable-list test-list", onKeyDown Msg.OnTestListKeyDown ] (createItems model)
        ]
