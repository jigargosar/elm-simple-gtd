module TodoStore.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import TodoStore exposing (EditMode(..), TodoStore)
import TodoStore.Model as Model
import TodoStore.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


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
allTodosView viewConfig editMode todoCollection =
    div []
        [ h1 [] [ text "Stuff" ]
        , addTodoView editMode viewConfig
        , todoListView editMode viewConfig todoCollection
        ]


addTodoView editMode viewConfig =
    case editMode of
        EditNewTodoMode text ->
            addNewTodoView viewConfig text

        _ ->
            addTodoButton viewConfig


addTodoButton viewConfig =
    div []
        [ button [ onClick viewConfig.onAddTodoClicked ] [ text "Add" ]
        ]


addNewTodoView viewConfig text =
    input
        [ onInput viewConfig.onNewTodoTextChanged
        , value text
        , onBlur viewConfig.onNewTodoBlur
        , autofocus True
        , onEnter viewConfig.onNewTodoEnterPressed
        ]
        []


todoListView : EditMode -> ViewConfig msg -> TodoStore -> Html msg
todoListView editMode viewConfig todoCollection =
    let
        mapperArgs =
            ( (todoView editMode viewConfig), todoCollection )

        mapper =
            uncurry Model.mapAllExceptDeleted
    in
        div []
            [ ul [] (mapper mapperArgs)
            , ul [] (mapper mapperArgs)
            ]


todoView editMode viewConfig todo =
    let
        inner =
            case editMode of
                EditTodoMode editingTodo ->
                    if Todo.equalById editingTodo todo then
                        todoListEditView viewConfig editingTodo
                    else
                        todoListItemView viewConfig todo

                _ ->
                    todoListItemView viewConfig todo
    in
        div [] [ inner, hr [] [] ]


todoListItemView viewConfig todo =
    let
        deleteOnClick =
            onClick (viewConfig.onDeleteTodoClicked (Todo.getId todo))

        editOnClick =
            onClick (viewConfig.onEditTodoClicked todo)
    in
        div []
            [ button [ deleteOnClick ] [ text "x" ]
            , div [ editOnClick ] [ Todo.getText todo |> text ]
            ]


todoListEditView viewConfig todo =
    input
        [ onInput viewConfig.onEditTodoTextChanged
        , value (Todo.getText todo)
        , onBlur viewConfig.onEditTodoBlur
        , autofocus True
        , onEnter viewConfig.onEditTodoEnterPressed
        ]
        []
