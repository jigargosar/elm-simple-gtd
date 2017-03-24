module Main.View.AllTodoLists exposing (..)

import Dom
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Keyboard.Extra exposing (Key)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.Types exposing (EditMode(EditTodoMode))
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
import Main.Model as Model exposing (..)
import Main.Msg exposing (..)
import Todo as Todo exposing (TodoGroup(Inbox), Todo, TodoId)
import Flow.Model as Flow exposing (Node)
import Polymer.Paper as Paper exposing (badge, button, fab, iconButton, item, itemBody, material, menu, tab, tabs)
import Polymer.App exposing (..)
import FunctionExtra exposing (..)
import Todo.View
import TodoGroupViewModel exposing (TodoGroupViewModel, getTodoGroupsViewModel)


type alias ViewConfig msg =
    { onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Dom.Id -> Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : Todo -> msg
    , onEditTodoKeyUp : Todo -> Key -> msg
    , noOp : msg
    , onTodoMoveToClicked : TodoGroup -> Todo -> msg
    , now : Time
    , editMode : EditMode
    , onTodoDoneClicked : TodoId -> msg
    }


createTodoListViewConfig : Model -> ViewConfig Msg
createTodoListViewConfig model =
    { onDeleteTodoClicked = OnDeleteTodoClicked
    , onEditTodoClicked = OnEditTodoClicked
    , onEditTodoTextChanged = OnEditTodoTextChanged
    , onEditTodoBlur = OnEditTodoBlur
    , onEditTodoKeyUp = OnEditTodoKeyUp
    , noOp = NoOp
    , onTodoMoveToClicked = OnSetTodoGroupClicked
    , now = getNow model
    , editMode = getEditMode model
    , onTodoDoneClicked = OnTodoDoneClicked
    }


allTodoListByGroupView : Model -> Html Msg
allTodoListByGroupView =
    apply2 ( createTodoListViewConfig >> keyedTodoListView, getTodoGroupsViewModel )
        >> uncurry List.map
        >> Keyed.node "div" []


todoListView : Model -> Html Msg
todoListView =
    apply2 ( createTodoListViewConfig, Model.getFilteredTodoList )
        >> (\( vc, todoList ) -> Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView vc))


keyedTodoListView : ViewConfig Msg -> TodoGroupViewModel -> ( String, Html Msg )
keyedTodoListView vc vm =
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
