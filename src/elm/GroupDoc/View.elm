module GroupDoc.View exposing (..)

import Entity
import GroupDoc.ViewModel exposing (ViewModel)
import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import Html.Keyed
import Material
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
    ( vm.id, item todoView vm )


item todoView vm =
    let
        getTabIndexAVForTodo =
            Entity.TodoEntity >> vm.getTabIndexAVForEntity
    in
        Html.Keyed.node "div"
            [ class "collection" ]
            (( vm.id, headerItem vm ) :: (vm.todoList .|> todoView))


initHeaderKeyed vm =
    ( vm.id, headerItem vm )


headerItem : ViewModel -> Html Model.Msg
headerItem vm =
    let
        editButton =
            if vm.isEditable then
                Material.iconButton "create" [ onClickStopPropagation vm.startEditingMsg, vm.tabindexAV ]
            else
                span [] []

        archiveButton =
            Material.iconButton vm.archive.iconName [ onClickStopPropagation vm.archive.onClick, vm.tabindexAV ]

        editOrArchiveButton =
            if vm.archive.isArchived then
                archiveButton
            else
                editButton
    in
        div
            [ vm.tabindexAV
            , onFocusIn vm.onFocusIn
            , onKeyDown vm.onKeyDownMsg
            , classList [ "entity-item focusable-list-item collection-item" => True ]
            ]
            [ div [ class "layout horizontal justified center" ]
                [ h5 [ class "font-nowrap ellipsis" ]
                    [ View.Shared.badge (vm.namePrefix ++ vm.name) vm.count
                    ]
                , div [ class "layout horizontal center" ] [ editOrArchiveButton ]
                ]
            ]
