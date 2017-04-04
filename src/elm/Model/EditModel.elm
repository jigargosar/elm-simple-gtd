module Model.EditModel exposing (..)

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
    setEditModel (NewTodo text)


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
            , Model.getProjectNameOfTodo # model
            )
        >> uncurry4 EditTodoModel


updateEditTodoText : String -> EditTodoModel -> ModelF
updateEditTodoText text editTodoModel =
    setEditModel (EditTodo ({ editTodoModel | todoText = text }))


getMaybeEditTodoModel model =
    case getEditModel model of
        EditTodo model ->
            Just model

        _ ->
            Nothing


getEditNewTodoModel model =
    case getEditModel model of
        NewTodo model ->
            Just model

        _ ->
            Nothing


updateEditTodoProjectName : ProjectName -> EditTodoModel -> ModelF
updateEditTodoProjectName projectName editTodoModel =
    setEditModel (EditTodo ({ editTodoModel | projectName = projectName }))


deactivateEditingMode =
    setEditModel NotEditing
