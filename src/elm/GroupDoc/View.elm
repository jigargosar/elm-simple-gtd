module GroupDoc.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed
import Mat
import Toolkit.Operators exposing (..)
import Views.Badge
import X.Function.Infix exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)


--type alias KeyedView =
--    ( String, Html AppMsg )


initKeyed todoView vm =
    ( vm.key, item todoView vm )



--item : (TodoDoc -> KeyedView) -> GroupDocViewModel -> Html AppMsg


item todoView vm =
    Html.Keyed.node "div"
        [ class "collection" ]
        (( vm.key, headerItem vm ) :: (vm.todoList .|> todoView))


initHeaderKeyed vm =
    ( vm.key, headerItem vm )



--headerItem : GroupDocViewModel -> Html Msg.AppMsg


headerItem vm =
    let
        editButton =
            if vm.isEditable then
                Mat.iconBtn3 vm.onMdl
                    "create"
                    vm.tabindexAV
                    vm.startEditingMsg
            else
                span [] []

        archiveButton =
            Mat.iconBtn3 vm.onMdl
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
        [ id vm.domId
        , tabindex vm.tabindexAV
        , X.Html.onFocusIn vm.onFocusIn

        --        , onClick vm.onFocusIn
        , onKeyDown vm.onKeyDownMsg
        , classList [ "entity-item focusable-list-item collection-item" => True ]
        , attribute "data-key" vm.key
        ]
        [ div [ class "layout horizontal justified center" ]
            [ h5 [ class "font-nowrap ellipsis" ]
                [ Views.Badge.badge (vm.namePrefix ++ vm.name) vm.count
                ]
            , div [ class "layout horizontal center" ] [ editOrArchiveButton ]
            ]
        ]
