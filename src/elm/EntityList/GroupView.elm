module EntityList.GroupView exposing (..)

import Entity
import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import Html.Keyed
import Model
import Svg.Events exposing (onFocusIn)
import Todo.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.Shared exposing (defaultOkCancelDeleteButtons)
import WebComponents


initKeyed todoView vm =
    ( vm.id, init todoView vm )


initHeaderKeyed vm =
    ( vm.id, initHeader vm )


init todoView vm =
    let
        getTabIndexAVForTodo =
            Entity.TodoEntity >> vm.getTabIndexAVForEntity
    in
        div []
            [ initHeader vm
            , Html.Keyed.node "div"
                []
                (vm.todoList .|> todoView)
            ]


initHeader vm =
    let
        editButton =
            if vm.isEditable then
                WebComponents.iconButton "create"
                    [ class "flex-none", onClick vm.startEditingMsg, vm.tabindexAV ]
            else
                span [] []
    in
        div
            [ vm.tabindexAV
            , onFocusIn vm.onFocusIn
            , onKeyDown vm.onKeyDownMsg
            , classList [ "entity-item group-item focusable-list-item" => True ]
            ]
            [ div [ class "layout horizontal justified" ]
                [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
                , editButton
                ]
            ]
