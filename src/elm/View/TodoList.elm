module View.TodoList exposing (..)

import Dict exposing (Dict)
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


type alias ViewContext =
    { now : Time
    , encodedProjectNames : Json.Encode.Value
    , maybeEditTodoModel : Maybe EditTodoModel
    , projectIdToNameDict : Dict ProjectId ProjectName
    , selection : Set TodoId
    }


createViewContext : Model -> ViewContext
createViewContext model =
    { now = Model.getNow model
    , encodedProjectNames = Model.getProjectStore model |> ProjectStore.getEncodedProjectNames
    , maybeEditTodoModel = Model.EditMode.getMaybeEditTodoModel model
    , projectIdToNameDict = Model.getProjectStore model |> ProjectStore.getProjectIdToNameDict
    , selection = Model.getSelectedTodoIdSet model
    }


type alias TodoView =
    Todo -> ( TodoId, Html Msg )


todoViewFromModel : Model -> TodoView
todoViewFromModel =
    createViewContext
        >> (\vc todo ->
                ( Todo.getId todo
                , getTodoView vc todo
                )
           )


getTodoView vc todo =
    let
        notEditingView _ =
            View.Todo.todoViewNotEditing vc todo
    in
        case vc.maybeEditTodoModel of
            Just etm ->
                if Todo.equalById etm.todo todo then
                    (View.Todo.edit (createEditTodoViewModel vc etm))
                else
                    notEditingView ()

            Nothing ->
                notEditingView ()


createEditTodoViewModel : ViewContext -> EditTodoModel -> EditTodoViewModel
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
        , onKeyUp = Msg.EditTodoKeyUp etm
        , onTodoTextChanged = Msg.EditTodoTextChanged etm
        , onProjectNameChanged = Msg.EditTodoProjectNameChanged etm
        , encodedProjectNames = vc.encodedProjectNames
        }


filteredTodoListView : Model -> Html Msg
filteredTodoListView =
    apply2 ( todoViewFromModel, Model.TodoStore.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


groupByTodoContext : Model -> Html Msg
groupByTodoContext =
    apply2 ( todoViewFromModel >> maybeContextView, Model.TodoStore.groupByTodoContextViewModel )
        >> uncurry List.filterMap
        >> Keyed.node "div" []


maybeContextView : TodoView -> TodoContextViewModel -> Maybe ( String, Html Msg )
maybeContextView todoView vm =
    if vm.isEmpty then
        Nothing
    else
        Just
            ( vm.name
            , div [ class "todo-list-container" ]
                [ div [ class "todo-list-title" ]
                    [ div [ class "paper-badge-container" ]
                        [ span [] [ text vm.name ]
                        , badge [ intProperty "label" (vm.count) ] []
                        ]
                    ]
                , Keyed.node "paper-material" [ class "todo-list" ] (vm.todoList .|> todoView)
                ]
            )
