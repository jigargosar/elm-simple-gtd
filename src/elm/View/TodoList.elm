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
import Todo.View exposing (EditTodoViewModel)
import Tuple2
import View.Shared exposing (..)
import WebComponents


filtered : Model -> Html Msg
filtered =
    apply2
        ( View.Shared.createSharedViewModel >> Todo.View.initKeyed
        , Model.getFilteredTodoList
        )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-listbox"
                    [ stringProperty "selected" "0"
                    , stringProperty "selectedAttribute" "selected"
                    ]
                    (todoList .|> todoView)
           )


type EntityView
    = EntityView EntityViewModel
    | TodoView Todo.Model


listClampIndex list =
    let
        length =
            List.length list

        lastIndex =
            max 0 (length - 1)
    in
        clamp 0 lastIndex


groupByEntity : List EntityViewModel -> Model -> Html Msg
groupByEntity entityVMList model =
    let
        vc =
            View.Shared.createSharedViewModel model

        entityViewList =
            entityVMList
                |> List.concatMap
                    (\vm -> (EntityView vm) :: (vm.todoList .|> TodoView))
                |> List.indexedMap createListItemView

        createListItemView index entityView =
            let
                selectedIndex =
                    0

                isSelected =
                    index == selectedIndex
            in
                case entityView of
                    EntityView vm ->
                        ( vm.id, entityHeaderView vc vm )

                    TodoView todo ->
                        Todo.View.initKeyed vc todo

        prevNextIdPair : Msg.PrevNextIdPair
        prevNextIdPair =
            let
                idList =
                    entityVMList
                        |> List.concatMap (\vm -> vm.id :: (vm.todoList .|> Document.getId))

                focusedIndex =
                    idList
                        |> List.findIndex (equals vc.mainViewListFocusedDocumentId)
                        ?= 0
            in
                ( focusedIndex - 1, focusedIndex + 1 )
                    |> Tuple2.mapBoth
                        (listClampIndex idList
                            >> (List.getAt # idList)
                            >>?= vc.mainViewListFocusedDocumentId
                        )
    in
        Keyed.node "div"
            [ prevNextIdPair |> Msg.OnTodoListKeyDown |> onKeyDown ]
            (entityViewList)


groupByEntityWithId entityVMs id =
    let
        vmSingleton =
            entityVMs |> List.find (.id >> equals id) |> Maybe.toList
    in
        groupByEntity vmSingleton


entityHeaderView vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView vm) (editEntityView # vm)
    else
        defaultView vm


defaultView vm =
    div [ class "entity-item layout horizontal justified width--100" ]
        [ div [ class "font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
        , WebComponents.iconButton "create"
            [ class "flex-none", onClick vm.startEditingMsg, tabindex -1 ]
        ]


editEntityView editModel vm =
    div [ class "entity-item layout vertical" ]
        [ input
            [ class "edit-entity-name-input auto-focus"
            , stringProperty "label" "Name"
            , value (editModel.name)
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
