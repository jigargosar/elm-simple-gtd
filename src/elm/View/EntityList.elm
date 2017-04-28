module View.EntityList exposing (..)

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
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Maybe.Extra as Maybe
import Model.Internal as Model
import Model.TodoStore exposing (TodoContextViewModel)
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import Project
import Project
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, disabled, id, style, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, input, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import Entity.ViewModel
import View.Todo exposing (EditTodoViewModel)
import View.Shared exposing (..)


filtered : Model -> Html Msg
filtered =
    apply2 ( View.Shared.createSharedViewModel >> View.Todo.createKeyedItem, Model.TodoStore.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-listbox"
                    [ class "todo-list"
                    , stringProperty "selected" "0"
                    , stringProperty "selectable" "paper-item"
                    , stringProperty "selectedAttribute" "selected"
                    ]
                    (todoList .|> todoView)
           )


groupByEntity : List Entity.ViewModel.EntityItemModel -> Model -> Html Msg
groupByEntity entityVMs model =
    let
        vc =
            View.Shared.createSharedViewModel model

        todoListContainer vm =
            ( vm.id
            , div [ class "todo-list-container" ]
                [ entityListItemView vc vm
                , Paper.material []
                    [ Keyed.node "paper-listbox"
                        [ class "todo-list"
                        , stringProperty "selectable" "paper-item"
                        , stringProperty "selectedAttribute" "selected"
                        ]
                        (vm.todoList .|> View.Todo.createKeyedItem vc)
                    ]
                ]
            )
    in
        Keyed.node "div" [] (entityVMs .|> todoListContainer)


singletonEntity entityVMs id =
    let
        vmSingleton =
            entityVMs |> List.find (.id >> equals id) |> Maybe.toList
    in
        groupByEntity vmSingleton


entityListItemView vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView vm) (editEntityView # vm)
    else
        defaultView vm


defaultView vm =
    item []
        [ itemBody [] [ View.Shared.defaultBadge vm ]
        , showOnHover [ settingsButton vm.startEditingMsg ]
        , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
        ]


editEntityView editModel vm =
    material [ class "edit-entity-view" ]
        [ div []
            [ itemBody []
                [ input
                    [ class "edit-entity-name-input auto-focus"
                    , stringProperty "label" "Name"
                    , value (editModel.name)
                    , onInput vm.onNameChanged
                    , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")

                    --                        , onKeyUp vm.onKeyUp
                    ]
                    []
                ]
            ]
        , row
            [ button [ onClick vm.onSaveClicked ] [ "Save" |> text ]
            , button [ onClick vm.onCancelClicked ] [ "Cancel" |> text ]
            , expand []
            , trashButton vm.onDeleteClicked
            ]
        ]
