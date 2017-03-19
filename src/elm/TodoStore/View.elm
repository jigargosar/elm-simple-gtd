module TodoStore.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Keyboard.Extra exposing (Key)
import TodoStore exposing (TodoStore)
import TodoStore.Model as Model
import Todo as Todo exposing (EditMode, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo.View
import Html.Keyed as Keyed
import Polymer.Paper exposing (material)


type alias ViewConfig msg =
    { onAddTodoClicked : msg
    , onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : msg
    , onEditTodoKeyUp : Key -> msg
    , onNewTodoTextChanged : String -> msg
    , onNewTodoBlur : msg
    , onNewTodoEnterPressed : msg
    }


allTodosView : ViewConfig msg -> EditMode -> TodoStore -> Html msg
allTodosView viewConfig editMode todoStore =
    let
        typeToTodoList : Dict String (List Todo)
        typeToTodoList =
            Model.groupByType todoStore

        todoView : Todo -> ( TodoId, Html msg )
        todoView =
            Todo.View.todoView editMode viewConfig

        todoListContainers : List ( String, Html msg )
        todoListContainers =
            typeToTodoList |> Dict.map (todoListContainerView todoView) |> Dict.toList
    in
        Keyed.node "div" [] todoListContainers


todoListContainerView todoView listName todoList =
    div []
        [ div [ class "todo-list-title" ] [ text listName ]
        , material [ class "todo-list" ] [ Keyed.node "div" [] (todoList .|> todoView) ]
        ]
