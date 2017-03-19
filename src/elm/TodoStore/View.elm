module TodoStore.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import TodoStore exposing (TodoStore)
import TodoStore.Model as Model
import Todo as Todo exposing (EditMode, Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Dict exposing (Dict)
import Dict.Extra as Dict
import Todo.View


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

        todoView_ : Todo -> Html msg
        todoView_ =
            (Todo.View.todoView editMode viewConfig)
    in
        div [] (typeToTodoList |> Dict.map (todoGroupView todoView_) |> Dict.values)


todoGroupView todoView_ groupName todoList =
    div []
        --    node "paper-card"
        --        []
        [ h1 []
            [ text groupName ]
        , div [] (todoList .|> todoView_)
        ]
