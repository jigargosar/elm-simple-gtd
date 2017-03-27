module Main.View.AllTodoLists exposing (..)

import Dom
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import KeyboardExtra as KeyboardExtra exposing (KeyboardEvent, onEscape, onKeyUp)
import Types exposing (..)
import Polymer.Attributes exposing (icon)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Html exposing (Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model as Model
import Types exposing (Model)
import Todo as Todo exposing (TodoGroup(Inbox), Todo, TodoId)
import Flow.Model as Flow exposing (Node)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import Todo.View
import TodoGroupViewModel exposing (TodoGroupViewModel, getTodoGroupsViewModel)


type alias ViewConfig msg =
    { onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : Todo -> msg
    , onEditTodoKeyUp : Todo -> KeyboardEvent -> msg
    , noOp : msg
    , onTodoMoveToClicked : TodoGroup -> TodoId -> msg
    , now : Time
    , editMode : EditMode
    , onTodoDoneClicked : TodoId -> msg
    , onTodoStartClicked : TodoId -> msg
    }


createTodoListViewConfig : Model -> ViewConfig Msg
createTodoListViewConfig model =
    { onDeleteTodoClicked = Types.toggleDelete
    , onEditTodoClicked = startEditingTodo
    , onEditTodoTextChanged = onEditTodoInput
    , onEditTodoBlur = onEditTodoBlur
    , onEditTodoKeyUp = onEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = Types.setGroup
    , now = Model.getNow model
    , editMode = Model.getEditMode model
    , onTodoDoneClicked = Types.toggleDone
    , onTodoStartClicked = Types.start
    }


allTodoListByGroupView : Model -> Html Msg
allTodoListByGroupView =
    apply2 ( todoViewFromModel >> keyedTodoGroupView, getTodoGroupsViewModel )
        >> uncurry List.filterMap
        >> Keyed.node "div" []


todoListView : Model -> Html Msg
todoListView =
    apply2 ( todoViewFromModel, Model.getFilteredTodoList )
        >> (\( todoView, todoList ) ->
                Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
           )


todoViewFromModel =
    createTodoListViewConfig >> todoView


type alias TodoView =
    Todo -> ( TodoId, Html Msg )


keyedTodoGroupView : TodoView -> TodoGroupViewModel -> Maybe ( String, Html Msg )
keyedTodoGroupView todoView vm =
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


todoView : ViewConfig Msg -> TodoView
todoView vc todo =
    let
        todoId =
            Todo.getId todo

        notEditingView =
            Todo.View.todoViewNotEditing vc todo

        editingView todo =
            Todo.View.todoViewEditing vc todo

        todoViewHelp =
            case vc.editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        editingView editingTodo
                    else
                        notEditingView

                _ ->
                    notEditingView
    in
        ( todoId, todoViewHelp )
