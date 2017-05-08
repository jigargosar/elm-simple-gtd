module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Document
import Dom
import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyUp)
import ListSelection
import Maybe.Extra as Maybe
import Model.Internal as Model
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Project
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Entity.ViewModel exposing (EntityViewModel)
import Todo.View exposing (EditViewModel)
import Tuple2
import View.Shared exposing (..)
import ViewModel exposing (EntityView(..))
import WebComponents


filtered : ViewModel.Model -> Model -> Html Msg
filtered viewModel model =
    let
        vc =
            viewModel.shared

        createTodoView todo =
            Todo.View.initKeyed (Todo.View.createTodoViewModel vc todo)
    in
        model
            |> Model.getFilteredTodoList
            .|> createTodoView
            |> Keyed.node "paper-listbox"
                [ stringProperty "selected" "0"
                , stringProperty "selectedAttribute" "selected"
                ]


groupByEntity : ViewModel.Model -> List EntityViewModel -> Model -> Html Msg
groupByEntity viewModel entityVMList model =
    let
        vc =
            viewModel.shared

        entityIdViewPairList =
            entityVMList
                |> List.concatMap
                    (\vm ->
                        ( vm.id, GroupByEntity vm )
                            :: (vm.todoList .|> apply2 ( .id, TodoView ))
                    )

        findIndexOfId id =
            entityIdViewPairList
                |> List.findIndex (Tuple.first >> equals id)

        focusedIndex =
            ListSelection.getMaybeSelected model.listSelection
                ?+> findIndexOfId
                ?= 0

        entityViewList =
            entityIdViewPairList
                |> List.indexedMap createListItemView

        createListItemView index ( id, entityView ) =
            let
                focused =
                    index == focusedIndex

                tabindexValue =
                    if focused then
                        0
                    else
                        -1

                tabindexAV =
                    tabindex tabindexValue
            in
                case entityView of
                    GroupByEntity vm ->
                        ( vm.id, entityHeaderView tabindexAV vc vm )

                    TodoView todo ->
                        Todo.View.initKeyed (viewModel.createTodoViewModel todo)

        idList =
            entityVMList
                |> List.concatMap (\vm -> vm.id :: (vm.todoList .|> Document.getId))
    in
        Keyed.node "div"
            [ class "entity-list"
            , Msg.OnTodoListKeyDown idList |> onKeyDown
            ]
            entityViewList


groupByEntityWithId viewModel entityVMs id =
    let
        vmSingleton =
            entityVMs |> List.find (.id >> equals id) |> Maybe.toList
    in
        groupByEntity viewModel vmSingleton


entityHeaderView tabindexAV vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView tabindexAV vm) (editEntityView tabindexAV vm)
    else
        defaultView tabindexAV vm


defaultView tabindexAV vm =
    div
        [ class "entity-item layout horizontal justified width--100"
        , tabindexAV
        ]
        [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
        , WebComponents.iconButton "create"
            [ class "flex-none", onClick vm.startEditingMsg, tabindexAV ]
        ]


editEntityView tabindexAV vm form =
    div
        [ class "entity-item layout vertical"
        , tabindexAV
        ]
        [ input
            [ class "edit-entity-name-input auto-focus"
            , stringProperty "label" "Name"
            , value (form.name)
            , onInput vm.onNameChanged
            , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")

            --                        , onKeyUp vm.onKeyUp
            ]
            []
        , div [ class "layout horizontal" ]
            [ button [ onClick vm.onSaveClicked ] [ "Save" |> text ]
            , button [ onClick vm.onCancelClicked ] [ "Cancel" |> text ]
            , expand []
            , WebComponents.iconButton "delete" [ onClick Msg.SelectionTrashClicked ]
            ]
        ]
