module Main.View exposing (appView)

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


appView m =
    div []
        [ drawerLayoutView m
        , fab
            [ id "add-fab"
            , attribute "icon" "add"
            , onClick (OnAddTodoClicked newTodoInputId)
            ]
            []
        ]


drawerLayoutView m =
    drawerLayout []
        [ drawer [ attribute "slot" "drawer" ]
            [ toolbar [] [ text "Simple GTD" ]
            , div [ style [ "height" => "100vh", "overflow" => "auto" ] ]
                [ appDrawerMenuView m
                ]
            ]
        , headerLayout []
            [ header
                [ attribute "reveals" "true"
                , attribute "fixed" "true"
                , attribute "condenses" "true"
                , attribute "effects" "waterfall"
                , attribute "slot" "header"
                ]
                [ toolbar
                    []
                    [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
                    , addTodoView (getEditMode m)
                    ]
                ]
            , div [ id "center-view" ] [ centerView m ]
            ]
        ]


addTodoView editMode =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView text

        _ ->
            span [] []


newTodoInputId =
    "new-todo-input"


addNewTodoView text =
    Paper.input
        [ id newTodoInputId
        , onInput OnNewTodoTextChanged
        , value text
        , onBlur OnNewTodoBlur
        , onKeyUp OnNewTodoKeyUp
        , autofocus True
        ]
        []


centerView m =
    case getViewState m of
        TodoListViewState ->
            todoListView m

        InboxFlowViewState maybeTodo inboxFlowModel ->
            InboxFlow.View.view maybeTodo inboxFlowModel


todoListView m =
    allTodosView (createTodoListViewConfig m) m



--    div [] []


allTodosView : ViewConfig msg -> Model -> Html msg
allTodosView vc model =
    let
        todoListViewsWithKey : List ( String, Html msg )
        todoListViewsWithKey =
            model |> getTodoList >> Todo.todoListsByType .|> todoListViewWithKey (todoView vc)
    in
        Keyed.node "div" [] todoListViewsWithKey


todoListViewWithKey todoView ( listTitle, todoList ) =
    ( listTitle
    , div [ class "todo-list-container" ]
        [ div [ class "todo-list-title" ]
            [ div [ class "paper-badge-container" ]
                [ span [] [ text listTitle ]
                , badge [ intProperty "label" (List.length todoList) ] []
                ]
            ]
        , Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
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
