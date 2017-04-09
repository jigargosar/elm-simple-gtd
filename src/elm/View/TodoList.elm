module View.TodoList exposing (..)

import Context
import Dict exposing (Dict)
import Dict.Extra as Dict
import Dom
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
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
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import View.Project
import View.Todo exposing (EditTodoViewModel)
import View.Context
import View.Shared exposing (SharedViewModel)


filteredTodoListView : Model -> Html Msg
filteredTodoListView =
    apply2 ( View.Shared.create >> View.Todo.listItemView, Model.TodoStore.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


groupByContextView : List View.Context.ViewModel -> Model -> Html Msg
groupByContextView contextVMs model =
    let
        vc =
            View.Shared.create model

        contextViewFromVM =
            contextView vc
    in
        Keyed.node "div" [] (contextVMs .|> contextViewFromVM)


contextView vc vm =
    ( vm.name
    , div [ class "todo-list-container" ]
        [ div [ class "todo-list-title" ]
            [ div [ class "paper-badge-container" ]
                [ span [] [ text vm.name ]
                , badge [ intProperty "label" (vm.count) ] []
                ]
            ]
        , Keyed.node "paper-material" [ class "todo-list" ] (vm.todoList .|> View.Todo.listItemView vc)
        ]
    )


groupByProjectView : List View.Project.ViewModel -> Model -> Html Msg
groupByProjectView projectVMs model =
    let
        vc =
            View.Shared.create model

        projectViewFromVM =
            projectView vc
    in
        Keyed.node "div" [] (projectVMs .|> projectViewFromVM)


projectView vc vm =
    ( vm.name
    , div [ class "todo-list-container" ]
        [ div [ class "todo-list-title" ]
            [ div [ class "paper-badge-container" ]
                [ span [] [ text vm.name ]
                , badge [ intProperty "label" (vm.count) ] []
                ]
            ]
        , Keyed.node "paper-material" [ class "todo-list" ] (vm.todoList .|> View.Todo.listItemView vc)
        ]
    )
