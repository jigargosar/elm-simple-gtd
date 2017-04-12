module Model.EditMode exposing (..)

import Context
import EditMode exposing (EditMode, EditTodoModel)
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model exposing (..)
import PouchDB
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
    setEditMode (EditMode.createNewTodoModel text)


setEditModelToEditTodo : Todo.Model -> ModelF
setEditModelToEditTodo todo =
    updateEditMode (createEditTodoModel todo)


setEditModeToEditEntity : Entity -> ModelF
setEditModeToEditEntity entity =
    setEditMode (createEntityEditMode entity)


updateEditModeNameChanged editMode newName entity =
    case editMode of
        EditMode.EditContext ecm ->
            setEditMode (EditMode.editContextSetName newName ecm)

        EditMode.EditProject epm ->
            setEditMode (EditMode.editProjectSetName newName epm)

        _ ->
            identity


updateEditModeSave model =
    case model.editMode of
        EditMode.EditContext ecm ->
            ecm.model
                |> Context.setName ecm.name
                |> Context.setModifiedAt model.now
                |> (PouchDB.update # model.contextStore)
                |> (setContextStore # model)

        EditMode.EditProject epm ->
            epm.model
                |> Project.setName epm.name
                |> Project.setModifiedAt model.now
                |> (PouchDB.update # model.contextStore)
                |> (setProjectStore # model)

        _ ->
            model


setContextStore contextStore model =
    { model | contextStore = contextStore }


createEntityEditMode : Entity -> EditMode
createEntityEditMode entity =
    case entity of
        ContextEntity model ->
            EditMode.editContextMode model

        ProjectEntity model ->
            EditMode.editProjectMode model


createEditTodoModel : Todo.Model -> Model -> EditMode
createEditTodoModel todo model =
    let
        projectName =
            Model.getMaybeProjectNameOfTodo todo model ?= ""

        contextName =
            Model.getContextNameOfTodo todo model ?= ""
    in
        EditMode.createEditTodoModel todo projectName contextName


updateEditTodoText : String -> EditTodoModel -> ModelF
updateEditTodoText text editTodoModel =
    setEditMode (EditMode.updateEditTodoText text editTodoModel)


getMaybeEditTodoModel =
    getEditMode >> EditMode.getMaybeEditTodoModel


getEditNewTodoModel =
    getEditMode >> EditMode.getNewTodoModel


updateEditTodoProjectName : Project.Name -> EditTodoModel -> ModelF
updateEditTodoProjectName projectName editTodoModel =
    setEditMode (EditMode.updateEditTodoProjectName projectName editTodoModel)


updateEditTodoContextName : Context.Name -> EditTodoModel -> ModelF
updateEditTodoContextName contextName editTodoModel =
    setEditMode (EditMode.updateEditTodoProjectName contextName editTodoModel)


deactivateEditingMode =
    setEditMode EditMode.none
