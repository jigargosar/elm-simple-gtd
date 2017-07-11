module Model.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (..)
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import LaunchBar.Models
import Menu
import Model.Internal exposing (setEditMode)
import Project
import Return
import Time exposing (Time)
import Todo
import Todo.GroupForm
import Todo.NewForm
import Todo.ReminderForm
import Types exposing (AppModel, ModelF)
import Stores
import Todo.Types exposing (TodoAction(..), TodoDoc)
import X.Record exposing (set)


saveCurrentForm model =
    case model.editMode of
        XMEditContext form ->
            model
                |> Stores.updateContext form.id
                    (Context.setName form.name)

        XMEditProject form ->
            model
                |> Stores.updateProject form.id
                    (Project.setName form.name)

        XMEditTodo form ->
            model
                |> Stores.updateTodo (TA_SetText form.todoText) form.id

        XMEditTodoReminder form ->
            model
                |> Stores.updateTodo (TA_SetScheduleFromMaybeTime (Todo.ReminderForm.getMaybeTime form)) form.id

        XMNewTodo form ->
            saveNewTodoForm form model

        XMEditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        XMSetup form ->
            saveNewTodoForm form model

        _ ->
            model |> Return.singleton


saveNewTodoForm form model =
    Stores.insertTodo (Todo.init model.now (form |> Todo.NewForm.getText)) model
        |> Tuple.mapFirst getDocId
        |> uncurry
            (\todoId ->
                Stores.updateTodo
                    (case form.referenceEntity of
                        TodoEntity fromTodo ->
                            (TA_CopyProjectAndContextId fromTodo)

                        GroupEntity g ->
                            case g of
                                ContextEntity context ->
                                    (TA_SetContext context)

                                ProjectEntity project ->
                                    (TA_SetProject project)
                    )
                    todoId
                    >> Tuple.mapFirst (Stores.setFocusInEntityFromTodoId todoId)
            )


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    setEditMode (Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo) model


updateNewTodoText form text =
    setEditMode (Todo.NewForm.setText text form |> XMNewTodo)


startEditingReminder : TodoDoc -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> XMEditTodoReminder)


updateEditModeM : (AppModel -> ExclusiveMode) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


startEditingTodoProject : TodoDoc -> ModelF
startEditingTodoProject todo =
    setEditMode (Todo.GroupForm.init todo |> XMEditTodoProject)


startEditingTodoContext : TodoDoc -> ModelF
startEditingTodoContext todo =
    setEditMode (Todo.GroupForm.init todo |> XMEditTodoContext)


showMainMenu =
    setEditMode (Menu.initState |> XMMainMenu)


deactivateEditingMode =
    setEditMode ExclusiveMode.none
