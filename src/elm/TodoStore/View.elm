module TodoStore.View exposing (..)

import Dom
import Html exposing (Html, div, hr, span, text)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (intProperty)
import Html.Events exposing (..)
import Keyboard.Extra exposing (Key)
import Main.Msg exposing (..)
import Polymer.Attributes exposing (icon, stringProperty)
import TodoStore exposing (TodoStore)
import TodoStore.Model as Model
import Todo as Todo exposing (EditMode(EditTodoMode), Group(Inbox), Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo.View
import Html.Keyed as Keyed
import Polymer.Paper exposing (..)
import FunctionExtra exposing (..)
import Time exposing (Time)


type alias ViewConfig msg =
    { onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Dom.Id -> Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : msg
    , onEditTodoKeyUp : Key -> msg
    , noOp : msg
    , onTodoMoveToClicked : Group -> Todo -> msg
    , now : Time
    , editMode : EditMode
    , onTodoDoneClicked : TodoId -> msg
    }


todoView : ViewConfig msg -> Todo -> ( TodoId, Html msg )
todoView vc todo =
    let
        todoId =
            Todo.getId todo

        editingTodoTuple =
            case vc.editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        ( True, editingTodo )
                    else
                        ( False, todo )

                _ ->
                    ( False, todo )

        todoView =
            Todo.View.todoView vc editingTodoTuple

        todoView2 =
            case vc.editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        Todo.View.todoViewEditing vc editingTodo
                    else
                        Todo.View.todoViewNotEditing vc todo

                _ ->
                    Todo.View.todoViewNotEditing vc todo
    in
        ( todoId, todoView )


allTodosView : ViewConfig msg -> TodoStore -> Html msg
allTodosView vc todoStore =
    let
        todoListViewsWithKey : List ( String, Html msg )
        todoListViewsWithKey =
            Model.getTodoLists todoStore .|> todoListViewWithKey (todoView vc)
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


drawerMenu todoStore =
    menu
        [ stringProperty "selected" "0"
        ]
        ([ item [ onClick OnShowTodoList ] [ text "All" ]
         , hr [] []
         ]
            ++ listTypeMenuItems todoStore
        )


listTypeMenuItems =
    Model.getTodoLists2
        >> List.map listTypeMenuItem


listTypeMenuItem ( listType, todoList ) =
    let
        ltName =
            Todo.listTypeToName listType
    in
        item [ class "has-hover-items" ]
            ([ span [ id ltName ] [ text (ltName) ]
             , itemBody [] []
             , badge
                [ classList
                    [ "hidden" => (List.length todoList == 0)
                    , "drawer-list-type-badge" => True
                    ]
                , intProperty "label" (List.length todoList)
                , attribute "for" ltName
                ]
                []
             ]
                ++ addHoverItems listType
            )


addHoverItems listType =
    case listType of
        Inbox ->
            [ iconButton
                [ class "hover-items"
                , icon "vaadin-icons:start-cog"
                , onClick OnProcessInbox
                ]
                []
            ]

        _ ->
            []
