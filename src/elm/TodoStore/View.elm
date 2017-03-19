module TodoStore.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import TodoStore exposing (TodoStore)
import TodoStore.Model as Model
import Todo as Todo exposing (EditMode, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo.View
import Html.Keyed as Keyed


type alias ViewConfig msg =
    { onAddTodoClicked : msg
    , onDeleteTodoClicked : TodoId -> msg
    , onEditTodoClicked : Todo -> msg
    , onEditTodoTextChanged : String -> msg
    , onEditTodoBlur : msg
    , onEditTodoEnterPressed : msg
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

        todoView_ : Todo -> ( TodoId, Html msg )
        todoView_ =
            (Todo.View.todoView editMode viewConfig)
    in
        Keyed.node "div" [] (typeToTodoList |> Dict.map (todoGroupView todoView_) |> Dict.toList)


todoGroupView todoView_ groupName todoList =
    div [ class "list-group-view" ]
        [ div [ class "group-title" ] [ text groupName ]
        , Keyed.node "div" [] (todoList .|> todoView_)
        ]
