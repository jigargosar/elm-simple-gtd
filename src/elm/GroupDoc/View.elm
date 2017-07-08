module GroupDoc.View exposing (..)

import Entity
import Entity.Types
import GroupDoc.ViewModel exposing (ViewModel)
import Msg
import X.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed
import Mat
import Model
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import View.Shared exposing (defaultOkCancelDeleteButtons)
import X.Html exposing (onClickStopPropagation)


initKeyed todoView vm =
    ( vm.id, item todoView vm )


item todoView vm =
    let
        getTabIndexAVForTodo =
            Entity.Types.Todo >> vm.getTabIndexAVForEntity
    in
        Html.Keyed.node "div"
            [ class "collection" ]
            (( vm.id, headerItem vm ) :: (vm.todoList .|> todoView))


initHeaderKeyed vm =
    ( vm.id, headerItem vm )


headerItem : ViewModel -> Html Msg.Msg
headerItem vm =
    let
        editButton =
            if vm.isEditable then
                Mat.iconBtn3 Msg.OnMdl
                    "create"
                    vm.tabindexAV
                    vm.startEditingMsg
            else
                span [] []

        archiveButton =
            Mat.iconBtn3 Msg.OnMdl
                vm.archive.iconName
                vm.tabindexAV
                vm.archive.onClick

        editOrArchiveButton =
            if vm.archive.isArchived then
                archiveButton
            else
                editButton
    in
        div
            [ tabindex vm.tabindexAV
            , X.Html.onFocusIn vm.onFocusIn
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
