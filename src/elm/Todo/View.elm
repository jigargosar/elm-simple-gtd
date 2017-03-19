module Todo.View exposing (..)

import Json.Decode
import Todo exposing (EditMode(EditTodoMode))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionalHelpers exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)


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
        ( Todo.getId todo, div [] [ inner, hr [] [] ] )


onTap msg =
    on "tap" (Json.Decode.succeed msg)


todoListItemView viewConfig todo =
    let
        deleteOnClick =
            onTap (viewConfig.onDeleteTodoClicked (Todo.getId todo))

        editOnClick =
            onClick (viewConfig.onEditTodoClicked todo)
    in
        node "paper-item"
            --        node "div"
            []
            [ node "paper-item-body"
                []
                [ node "paper-button" [ attribute "raised" "true", deleteOnClick ] [ text "x" ]
                , div [ editOnClick ] [ Todo.getText todo |> text ]
                ]
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
