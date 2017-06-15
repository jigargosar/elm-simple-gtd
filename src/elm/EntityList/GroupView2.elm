module EntityList.GroupView2 exposing (..)

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


initKeyed appViewModel vm =
    ( vm.id, init appViewModel vm )


init appViewModel vm =
    let
        editButton =
            if vm.isEditable then
                WebComponents.iconButton "create"
                    [ class "flex-none", onClick vm.startEditingMsg, vm.tabindexAV ]
            else
                span [] []

        getTabIndexAVForTodo =
            Entity.TodoEntity >> vm.getTabIndexAVForEntity
    in
        div []
            [ div
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
            , Html.Keyed.node "div"
                []
                (vm.todoList
                    .|> (\todo ->
                            appViewModel.createTodoViewModel (getTabIndexAVForTodo todo) todo
                                |> Todo.View.initKeyed
                        )
                )
            ]
