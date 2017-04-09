module Model.EditMode exposing (..)

import Context
import EditMode exposing (EditMode, EditTodoModel)
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model exposing (..)
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Msg exposing (..)
import Model.Types exposing (..)
import Project


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditMode (EditMode.newTodo text)


setEditModelToEditTodo : Todo.Model -> ModelF
setEditModelToEditTodo todo =
    updateEditModel (createEditTodoModel todo)


createEditTodoModel : Todo.Model -> Model -> EditMode
createEditTodoModel todo model =
    let
        projectName =
            Model.getMaybeProjectNameOfTodo todo model ?= ""

        contextName =
            Model.getContextNameOfTodo todo model ?= ""
    in
        EditMode.editTodo todo projectName contextName


updateEditTodoText : String -> EditTodoModel -> ModelF
updateEditTodoText text editTodoModel =
    setEditMode (EditMode.updateEditTodoText text editTodoModel)


getMaybeEditTodoModel =
    getEditMode >> EditMode.getMaybeEditTodoModel


getEditNewTodoModel =
    getEditMode >> EditMode.getEditNewTodoModel


updateEditTodoProjectName : Project.Name -> EditTodoModel -> ModelF
updateEditTodoProjectName projectName editTodoModel =
    setEditMode (EditMode.updateEditTodoProjectName projectName editTodoModel)


updateEditTodoContextName : Context.Name -> EditTodoModel -> ModelF
updateEditTodoContextName contextName editTodoModel =
    setEditMode (EditMode.updateEditTodoProjectName contextName editTodoModel)


deactivateEditingMode =
    setEditMode EditMode.notEditing
