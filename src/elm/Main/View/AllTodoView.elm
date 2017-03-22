module Main.View.AllTodoView exposing (..)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Polymer.Attributes exposing (icon)
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
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (EditMode(..), Group(Inbox), Todo, TodoId)
import TodoStore.View exposing (ViewConfig)
import Flow.Model as Flow exposing (Node)
import InboxFlow
import InboxFlow.View
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import Main.View.DrawerMenu exposing (appDrawerMenuView)
import Todo.View


createTodoListViewConfig : Model -> TodoStore.View.ViewConfig Msg
createTodoListViewConfig model =
    { onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoKeyUp = OnEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = OnTodoMoveToClicked
    , now = getNow model
    , editMode = getEditMode model
    , onTodoDoneClicked = OnTodoDoneClicked
    }


todoListViewsWithKey : Model -> List ( String, Html Msg )
todoListViewsWithKey =
    apply2 ( createTodoListViewConfig >> todoListViewWithKey, todoListsByType )
        >> uncurry List.map


allTodosView : Model -> Html Msg
allTodosView m =
    Keyed.node "div" [] (todoListViewsWithKey m)


todoListViewWithKey vc ( listTitle, todoList ) =
    ( listTitle
    , div [ class "todo-list-container" ]
        [ div [ class "todo-list-title" ]
            [ div [ class "paper-badge-container" ]
                [ span [] [ text listTitle ]
                , badge [ intProperty "label" (List.length todoList) ] []
                ]
            ]
        , Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView vc)
        ]
    )


todoView : ViewConfig msg -> Todo -> ( TodoId, Html msg )
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
