module View.TodoList exposing (..)

import Dom
import EditModel.Types exposing (EditTodoModel)
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import Ext.Keyboard as Keyboard exposing (KeyboardEvent, onEscape, onKeyUp)
import Model.EditModel
import Model.Internal as Model
import Model.TodoList exposing (TodoContextViewModel)
import Msg exposing (..)
import Polymer.Attributes exposing (icon)
import ProjectStore
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


type alias Context =
    { now : Time
    , encodedProjectNames : Json.Encode.Value
    , maybeEditTodoModel : Maybe EditTodoModel
    }


createViewContext : Model -> Context
createViewContext model =
    { now = Model.getNow model
    , encodedProjectNames = Model.getProjectStore model |> ProjectStore.getEncodedProjectNames
    , maybeEditTodoModel = Model.EditModel.getMaybeEditTodoModel model
    }


type alias TodoView =
    Todo -> ( TodoId, Html Msg )


todoViewFromModel : Model -> TodoView
todoViewFromModel =
    createViewContext >> keyedTodoView


keyedTodoView : Context -> TodoView
keyedTodoView vc todo =
    ( Todo.getId todo
    , getTodoView vc todo
    )


getTodoView vc todo =
    vc.maybeEditTodoModel ?+> foo vc todo ?= View.Todo.todoViewNotEditing vc todo


foo : Context -> Todo -> EditTodoModel -> Maybe (Html Msg)
foo vc todo etm =
    if Todo.equalById etm.todo todo then
        let
            viewModel : EditTodoViewModel
            viewModel =
                { todoText = etm.todoText
                , todoId = etm.todoId
                , projectName = etm.projectName
                , onKeyUp = Msg.EditTodoKeyUp etm
                , onTodoTextChanged = Msg.EditTodoTextChanged etm
                , onProjectNameChanged = Msg.EditTodoProjectNameChanged etm
                , encodedProjectNames = vc.encodedProjectNames
                }
        in
            Just (View.Todo.editTodoView viewModel)
    else
        Nothing


todoListView : Model -> Html Msg
todoListView =
    apply2 ( todoViewFromModel, Model.TodoList.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


allTodoListByTodoContextView : Model -> Html Msg
allTodoListByTodoContextView =
    apply2 ( todoViewFromModel >> keyedTodoContextView, Model.TodoList.getTodoContextsViewModel )
        >> uncurry List.filterMap
        >> Keyed.node "div" []


keyedTodoContextView : TodoView -> TodoContextViewModel -> Maybe ( String, Html Msg )
keyedTodoContextView todoView vm =
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
