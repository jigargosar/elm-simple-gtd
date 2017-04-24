module Model.EditMode exposing (..)

import Context
import Document
import EditMode exposing (EditMode, TodoForm)
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model exposing (..)
import Model.TodoStore
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Msg exposing (..)
import Model.Types exposing (..)
import Project
import Store
import Todo.Edit


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditMode (EditMode.createNewTodoModel text)


startEditingTodo : Todo.Model -> ModelF
startEditingTodo todo =
    updateEditMode (createEditTodoMode todo)


startEditingReminder : Todo.Model -> ModelF
startEditingReminder todo =
    updateEditMode (createEditReminderTodoMode todo)


startEditingTodoById : Todo.Id -> ModelF
startEditingTodoById id =
    applyMaybeWith (Model.TodoStore.findTodoById id)
        (createEditTodoMode >> updateEditMode)


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    setEditMode (createEntityEditMode entity model) model


updateEditModeNameChanged newName entity model =
    case model.editMode of
        EditMode.EditContext ecm ->
            setEditMode (EditMode.editContextSetName newName ecm) model

        EditMode.EditProject epm ->
            setEditMode (EditMode.editProjectSetName newName epm) model

        _ ->
            model


toggleDeletedForEntity : Entity -> ModelF
toggleDeletedForEntity entity model =
    case entity of
        ContextEntity context ->
            context
                |> Document.toggleDeleted
                |> Context.setModifiedAt model.now
                |> (Store.update # model.contextStore)
                |> (setContextStore # model)

        ProjectEntity project ->
            project
                |> Document.toggleDeleted
                |> Project.setModifiedAt model.now
                |> (Store.update # model.projectStore)
                |> (setProjectStore # model)

        TodoEntity todo ->
            let
                _ =
                    Debug.log "todo deleted called" (todo)
            in
                Model.TodoStore.updateTodo [ Todo.ToggleDeleted ] todo model


saveEditModeEntity model =
    case model.editMode of
        EditMode.EditContext ecm ->
            Store.findById ecm.id model.contextStore
                ?|> Context.setName ecm.name
                >> Context.setModifiedAt model.now
                >> (Store.update # model.contextStore)
                >> (setContextStore # model)
                ?= model

        EditMode.EditProject epm ->
            Store.findById epm.id model.projectStore
                ?|> Project.setName epm.name
                >> Project.setModifiedAt model.now
                >> (Store.update # model.projectStore)
                >> (setProjectStore # model)
                ?= model

        EditMode.EditTodo form ->
            case form of
                Todo.Edit.TextForm formModel ->
                    model
                        |> --                Model.insertProjectIfNotExist form.projectName
                           --                >> Model.insertContextIfNotExist form.contextName
                           Model.updateTodoFromEditTodoForm formModel
                        >> startEditingTodoById formModel.id

                _ ->
                    model

        _ ->
            model


setContextStore contextStore model =
    { model | contextStore = contextStore }


createEntityEditMode : Entity -> Model -> EditMode
createEntityEditMode entity model =
    case entity of
        ContextEntity context ->
            EditMode.editContextMode context

        ProjectEntity project ->
            EditMode.editProjectMode project

        TodoEntity todo ->
            createEditTodoMode todo model


createEditTodoMode : Todo.Model -> Model -> EditMode
createEditTodoMode todo model =
    let
        projectName =
            Model.getMaybeProjectNameOfTodo todo model ?= ""

        contextName =
            Model.getContextNameOfTodo todo model ?= ""
    in
        Todo.Edit.createTextForm todo projectName contextName model.now |> EditMode.EditTodo


createEditReminderTodoMode : Todo.Model -> Model -> EditMode
createEditReminderTodoMode todo model =
    Todo.Edit.createReminderForm todo model.now |> EditMode.EditTodo


getMaybeEditTodoModel =
    getEditMode >> EditMode.getMaybeEditTodoModel


getEditNewTodoModel =
    getEditMode >> EditMode.getNewTodoModel


setEditTodoModel =
    EditMode.EditTodo >> setEditMode


deactivateEditingMode =
    setEditMode EditMode.none
