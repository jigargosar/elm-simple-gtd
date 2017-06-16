module EntityList.GroupView exposing (..)

import Entity
import EntityList.ViewModel exposing (GroupViewModel)
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
        div [ class "collection" ]
            [ initHeader vm
            , Html.Keyed.node "div" [] (vm.todoList .|> todoView)
            ]


initHeader : GroupViewModel -> Html Model.Msg
initHeader vm =
    let
        editButton =
            if vm.isEditable then
                WebComponents.iconButton "create"
                    [ class "self-center flex-none", onClick vm.startEditingMsg, vm.tabindexAV ]
            else
                span [] []
    in
        div
            [ vm.tabindexAV
            , onFocusIn vm.onFocusIn
            , onKeyDown vm.onKeyDownMsg
            , classList [ "entity-item focusable-list-item collection-item" => True ]
            ]
            [ div [ class "layout horizontal justified" ]
                [ h5 [ class "font-nowrap flex-auto layout horizontal" ]
                    [ div [ class "self-center" ] [ text vm.namePrefix ], View.Shared.defaultBadge vm ]
                , editButton
                ]
            ]
