module View exposing (init)

import Context
import Dom
import EditMode
import Firebase
import Firebase.View
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.Internal as Model
import Msg exposing (Msg, commonMsg)
import Polymer.Firebase
import ReminderOverlay
import Set
import Entity.ViewModel
import View.Header
import Main.View
import View.TodoList
import View.AppDrawer
import Maybe.Extra as Maybe
import Time exposing (Time)
import Ext.Time
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import List.Extra as List
import Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (dialog, material)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (showReminderOverlay)
import View.Shared exposing (..)
import Todo.View
import ViewModel
import WebComponents exposing (doneAllIconP, dynamicAlign, icon, iconA, iconButton, iconTextButton, onBoolPropertyChanged, onPropertyChanged, paperIconButton, slotDropdownContent, slotDropdownTrigger, testDialog)
import Ext.Html
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


init m =
    div [ id "root" ]
        ([ Firebase.View.init m
         , appView m
         ]
        )


appView m =
    div [ id "app-view" ]
        [ appDrawerLayoutView m
        , addTodoFab m
        , showReminderOverlay m
        ]


bottomSheet =
    div [ class "full-view" ]
        [ Paper.material [ style [ "background-color" => "white" ], class "fixed-bottom", attribute "elevation" "5" ]
            [ Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            ]
        ]


appDrawerLayoutView m =
    let
        viewModel =
            ViewModel.create m

        forceNarrow =
            Model.getLayoutForceNarrow m

        onClickHandler : List Dom.Id -> Msg
        onClickHandler pathIdList =
            List.find (List.member # [ "context-dropdown", "project-dropdown" ]) pathIdList
                ?|> (\_ -> Msg.DeactivateEditingMode)
                ?= commonMsg.noOp

        onClickAttributeList =
            let
                return =
                    [ Ext.Html.onClickTargetPathHavingIds [ "context-dropdown", "project-dropdown" ] Msg.DeactivateEditingMode
                    ]
            in
                case m.editMode of
                    EditMode.EditTodoContext _ ->
                        --                        [ Ext.Html.onClickPathIds onClickHandler ]
                        return

                    EditMode.EditTodoProject _ ->
                        --                        [ Ext.Html.onClickPathIds onClickHandler ]
                        return

                    _ ->
                        []
    in
        App.drawerLayout
            ([ boolProperty "forceNarrow" forceNarrow
             , onBoolPropertyChanged "narrow" Msg.OnLayoutNarrowChanged
             ]
                ++ onClickAttributeList
            )
            [ View.AppDrawer.view viewModel m
            , App.headerLayout [ attribute "has-scrolling-region" "" ]
                [ View.Header.init viewModel m
                , Main.View.init viewModel m
                ]
            ]


addTodoFab m =
    Paper.fab
        [ id "add-fab"
        , attribute "icon" "add"
        , attribute "mini" ""
        , onClick Msg.NewTodo
        , tabindex -1
        ]
        []
