module Model.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (EntityType(GroupEntity, TodoEntity), GroupEntityType(ContextEntity, ProjectEntity))
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Project
import Return
import Todo
import Todo.NewForm
import Todo.ReminderForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (ModelF)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Stores
import Todo.Types exposing (TodoAction(..))
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
