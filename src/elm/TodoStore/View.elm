module TodoStore.View exposing (..)

import Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Keyboard.Extra exposing (Key)
import Polymer.Attributes exposing (stringProperty)
import TodoStore exposing (TodoStore)
import TodoStore.Model as Model
import Todo as Todo exposing (EditMode, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo.View
import Html.Keyed as Keyed
import Polymer.Paper exposing (badge, material)


type alias ViewConfig msg =
    { onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Dom.Id -> Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : msg
    , onEditTodoKeyUp : Key -> msg
    }


allTodosView : ViewConfig msg -> EditMode -> TodoStore -> Html msg
allTodosView viewConfig editMode todoStore =
    let
        todoView : Todo -> ( TodoId, Html msg )
        todoView =
            Todo.View.todoView editMode viewConfig

        todoListViewsWithKey : List ( String, Html msg )
        todoListViewsWithKey =
            Model.todoLists todoStore .|> todoListViewWithKey todoView
    in
        Keyed.node "div" [] todoListViewsWithKey


todoListViewWithKey todoView ( listTitle, todoList ) =
    ( listTitle
    , div []
        [ div [ id listTitle, class "todo-list-title" ] [ text listTitle ]
        , badge [ stringProperty "for" listTitle, stringProperty "label" "10" ] []
        , Keyed.node "paper-material" [ class "todo-list" ] (todoList .|> todoView)
        ]
    )
