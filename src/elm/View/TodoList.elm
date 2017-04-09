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
import Project exposing (ProjectId, ProjectName)
import ProjectStore
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
import Todo.Types exposing (..)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import Ext.Function exposing (..)
import View.Todo exposing (EditTodoViewModel)
import View.Context
import View.MainViewModel exposing (MainViewModel)


type alias TodoView =
    Todo -> ( TodoId, Html Msg )


todoViewFromModel : Model -> TodoView
todoViewFromModel =
    View.MainViewModel.create >> todoView


todoView vc todo =
    let
        notEditingView _ =
            View.Todo.default vc todo

        view =
            case vc.maybeEditTodoModel of
                Just etm ->
                    if Todo.equalById etm.todo todo then
                        (View.Todo.edit (createEditTodoViewModel vc etm))
                    else
                        notEditingView ()

                Nothing ->
                    notEditingView ()
    in
        ( Todo.getId todo, view )


createEditTodoViewModel : MainViewModel -> EditTodoModel -> EditTodoViewModel
createEditTodoViewModel vc etm =
    let
        todoId =
            etm.todoId
    in
        { todo =
            { text = etm.todoText
            , id = todoId
            , inputId = "edit-todo-input-" ++ todoId
            }
        , project =
            { name = etm.projectName
            , inputId = "edit-todo-project-input-" ++ todoId
            }
        , context =
            { name = etm.contextName
            , inputId = "edit-todo-context-input-" ++ todoId
            }
        , onKeyUp = Msg.EditTodoKeyUp etm
        , onTodoTextChanged = Msg.EditTodoTextChanged etm
        , onProjectNameChanged = Msg.EditTodoProjectNameChanged etm
        , onContextNameChanged = Msg.EditTodoContextNameChanged etm
        , encodedProjectNames = vc.encodedProjectNames
        , encodedContextNames = vc.encodedContextNames
        }


filteredTodoListView : Model -> Html Msg
filteredTodoListView =
    apply2 ( todoViewFromModel, Model.TodoStore.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


groupByContextView : List View.Context.ViewModel -> Model -> Html Msg
groupByContextView contextVMs model =
    let
        vc =
            View.MainViewModel.create model

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
        , Keyed.node "paper-material" [ class "todo-list" ] (vm.todoList .|> todoView vc)
        ]
    )
