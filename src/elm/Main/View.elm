module Main.View exposing (appView)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.View.AllTodoView exposing (allTodosView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (EditMode(..), TodoGroup(Inbox), Todo, TodoId)
import TodoStore.View exposing (ViewConfig)
import Flow.Model as Flow exposing (Node)
import InboxFlow
import InboxFlow.View
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import Main.View.DrawerMenu exposing (appDrawerMenuView)
import Todo.View


appView m =
    div []
        [ appDrawerLayoutView m
        , addTodoFabView m
        ]


appDrawerLayoutView m =
    drawerLayout []
        [ appDrawerView m
        , headerLayout []
            [ appHeaderView m
            , appMainView m
            ]
        ]


appDrawerView m =
    drawer [ attribute "slot" "drawer" ]
        [ toolbar [] [ text "Simple GTD" ]
        , div [ style [ "height" => "100vh", "overflow" => "auto" ] ]
            [ appDrawerMenuView m
            ]
        ]


appHeaderView m =
    header
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        , attribute "slot" "header"
        ]
        [ toolbar
            []
            [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
            , newTodoInputView (getEditMode m)
            ]
        ]


appMainView m =
    div [ id "main-view" ]
        [ case getViewState m of
            TodoListViewState ->
                allTodosView m

            InboxFlowViewState maybeTodo inboxFlowModel ->
                InboxFlow.View.view maybeTodo inboxFlowModel
        ]


newTodoInputId =
    "new-todo-input"


newTodoInputView editMode =
    case editMode of
        EditNewTodoMode text ->
            Paper.input
                [ id newTodoInputId
                , onInput OnNewTodoTextChanged
                , value text
                , onBlur OnNewTodoBlur
                , onKeyUp OnNewTodoKeyUp
                , autofocus True
                ]
                []

        _ ->
            span [] []


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick (OnAddTodoClicked newTodoInputId)
        ]
        []


type AttributeType msg
    = AttrPresent (Attribute msg)
    | AttrAbsent
    | AttrMaybe (Maybe (Attribute msg))
    | L1 (List (AttributeType msg))
    | L2 (List (Attribute msg))


toAttributes : AttributeType msg -> List (Attribute msg)
toAttributes attributeType =
    case attributeType of
        AttrPresent attr ->
            [ attr ]

        AttrAbsent ->
            []

        AttrMaybe maybeAttr ->
            Maybe.toList maybeAttr

        L1 list ->
            list |> List.concatMap toAttributes

        L2 list ->
            list
