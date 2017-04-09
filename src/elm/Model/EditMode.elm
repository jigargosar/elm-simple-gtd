module Model.EditMode exposing (..)

import Context
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model exposing (..)
import Project exposing (Project, ProjectName)
import Todo
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


setEditModelToEditTodo : Todo.Model -> ModelF
setEditModelToEditTodo todo =
    updateEditModel (createEditTodoModel todo >> EditTodo)


createEditTodoModel : Todo.Model -> Model -> EditTodoModel
createEditTodoModel todo model =
    { todoId = Todo.getId todo
    , todo = todo
    , todoText = Todo.getText todo
    , projectName = Model.getMaybeProjectNameOfTodo todo model ?= ""
    , contextName = Model.getContextNameOfTodo todo model ?= ""
    }


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


updateEditTodoContextName : Context.Name -> EditTodoModel -> ModelF
updateEditTodoContextName contextName editTodoModel =
    setEditMode (EditTodo ({ editTodoModel | contextName = contextName }))


deactivateEditingMode =
    setEditMode NotEditing
