module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Dom
import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Maybe.Extra as Maybe
import Model.EditMode
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
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model as Model
import Model.Types exposing (..)
import Todo
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, input, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import View.Entity
import View.Todo exposing (EditTodoViewModel)
import View.Shared exposing (SharedViewModel)


filteredTodoListView : Model -> Html Msg
filteredTodoListView =
    apply2 ( View.Shared.create >> View.Todo.listItemView, Model.TodoStore.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


groupByEntityView : List View.Entity.ViewModel -> Model -> Html Msg
groupByEntityView entityVMs model =
    let
        vc =
            View.Shared.create model

        entityViewFromVM =
            entityView vc
    in
        Keyed.node "div" [] (entityVMs .|> entityViewFromVM)


singletonEntityView entityVMs id =
    let
        vmSingleton =
            entityVMs |> List.find (.id >> equals id) |> Maybe.toList
    in
        groupByEntityView vmSingleton


entityView vc vm =
    ( vm.name
    , div [ class "todo-list-container" ]
        [ entityHeaderView vc vm
        , Keyed.node "paper-material"
            [ class "todo-list" ]
            (vm.todoList .|> View.Todo.listItemView vc)
        ]
    )


entityHeaderView vc vm =
    let
        defaultView =
            item []
                [ View.Shared.defaultBadge vm
                , itemBody [] []
                , div [ class "show-on-hover" ]
                    [ iconButton
                        [ onClick vm.onSettingsClicked
                        , icon "settings"
                        ]
                        []
                    ]
                ]

        editEntityView =
            material []
                [ item []
                    [ itemBody []
                        [ input
                            [ --                        id vm.todo.inputId
                              class "edit-entity-name-input auto-focus"
                            , stringProperty "label" "Name"
                            , value (vm.name)
                            , onInput vm.onNameChanged

                            --                        , autofocus True
                            , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")

                            --                        , onKeyUp vm.onKeyUp
                            ]
                            []
                        ]
                    ]
                , item []
                    [ button [] [ "Save" |> text ]
                    , button [ onClick Msg.DeactivateEditingMode ] [ "Cancel" |> text ]
                    , button [] [ "Delete" |> text ]
                    ]
                ]
    in
        if vm.id /= "" then
            case vc.editMode of
                EditMode.EditProject epm ->
                    if epm.model.id == vm.id then
                        editEntityView
                    else
                        defaultView

                EditMode.EditContext etm ->
                    if etm.model.id == vm.id then
                        editEntityView
                    else
                        defaultView

                _ ->
                    defaultView
        else
            defaultView
