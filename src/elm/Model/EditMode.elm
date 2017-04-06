module Model.EditMode exposing (..)

import Maybe.Extra as Maybe
import Model
import Model.Internal as Model exposing (..)
import Project exposing (Project, ProjectName)
import Todo
import Todo.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Msg exposing (..)
import Model.Types exposing (..)
import ProjectStore


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditMode (NewTodoEditMode text)


setEditModelToEditTodo : Todo -> ModelF
setEditModelToEditTodo todo =
    updateEditModel (createEditTodoModel todo >> EditTodo)


createEditTodoModel : Todo -> Model -> EditTodoModel
createEditTodoModel todo model =
    todo
        |> apply4
            ( Todo.getId
            , identity
            , Todo.getText
            , Model.getMaybeProjectNameOfTodo # model >>?= ""
            )
        >> uncurry4 EditTodoModel


updateEditTodoText : String -> EditTodoModel -> ModelF
updateEditTodoText text editTodoModel =
    setEditMode (EditTodo ({ editTodoModel | todoText = text }))


getMaybeEditTodoModel model =
    case getEditMode model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getEditNewTodoModel model =
    case getEditMode model of
        NewTodoEditMode model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName : ProjectName -> EditTodoModel -> ModelF
updateEditTodoProjectName projectName editTodoModel =
    setEditMode (EditTodo ({ editTodoModel | projectName = projectName }))


deactivateEditingMode =
    setEditMode NotEditing
