module Model.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity
import Entity.Types exposing (EntityType(GroupEntity, TodoEntity), GroupEntityType(ContextEntity, ProjectEntity))
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import LaunchBar.Form
import Menu
import Msg
import Project
import Return
import Time exposing (Time)
import Todo
import Todo.GroupForm
import Todo.NewForm
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel, ModelF)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
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

        XMEditTodoContext form ->
            model |> Return.singleton

        XMEditTodoProject form ->
            model |> Return.singleton

        XMTodoMoreMenu _ ->
            model |> Return.singleton

        XMNewTodo form ->
            saveNewTodoForm form model

        XMEditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        XMLaunchBar form ->
            model |> Return.singleton

        XMMainMenu _ ->
            model |> Return.singleton

        XMNone ->
            model |> Return.singleton

        XMSignInOverlay ->
            model |> Return.singleton

        XMSetup form ->
            saveNewTodoForm form model


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


editMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setEditMode : ExclusiveMode -> ModelF
setEditMode =
    set editMode


startEditingEntity : EntityType -> ModelF
startEditingEntity entity model =
    setEditMode (ExclusiveMode.createEntityEditForm entity) model


createSetupExclusiveMode =
    XMSetup (Todo.NewForm.create Entity.inboxEntity "")


activateLaunchBar : Time -> ModelF
activateLaunchBar now =
    setEditMode (LaunchBar.Form.create now |> XMLaunchBar)


updateLaunchBarInput now text form =
    setEditMode (LaunchBar.Form.updateInput now text form |> XMLaunchBar)


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo |> Msg.OnStartExclusiveMode


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    setEditMode (Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo) model


activateNewTodoModeWithInboxAsReference : ModelF
activateNewTodoModeWithInboxAsReference =
    setEditMode (Todo.NewForm.create Entity.inboxEntity "" |> XMNewTodo)


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


updateEditModeNameChanged newName entity model =
    case model.editMode of
        XMEditContext ecm ->
            setEditMode (ExclusiveMode.editContextSetName newName ecm) model

        XMEditProject epm ->
            setEditMode (ExclusiveMode.editProjectSetName newName epm) model

        _ ->
            model


deactivateEditingMode =
    setEditMode ExclusiveMode.none
