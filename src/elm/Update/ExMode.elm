module Update.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), GroupEntityType(..), createContextEntity)
import ExclusiveMode.Types exposing (..)
import Project
import Return
import Todo
import Todo.Form
import Todo.Form
import Todo.FormTypes exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Stores
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelReturnF)


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

        XMTodo t ->
            case t of
                EditTodoForm form ->
                    let
                        updateTodo action =
                            Stores.updateTodo action form.id model
                    in
                        case form.etfMode of
                            ETFM_EditTodoText ->
                                updateTodo (TA_SetText form.text)

                            ETFM_EditTodoReminder ->
                                updateTodo (TA_SetScheduleFromMaybeTime (Todo.Form.computeMaybeTime form))

                            _ ->
                                model |> Return.singleton

                NoTodoForm ->
                    model |> Return.singleton

                AddTodoForm form ->
                    saveNewTodoForm form model

        XMEditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        _ ->
            model |> Return.singleton


inboxEntity =
    createContextEntity Context.null


saveNewTodoForm : AddTodoFormModel -> ModelReturnF
saveNewTodoForm form model =
    Stores.insertTodo (Todo.init model.now form.text) model
        |> Tuple.mapFirst getDocId
        |> uncurry
            (\todoId ->
                let
                    referenceEntity =
                        case form.atfMode of
                            ATFM_AddToInbox ->
                                inboxEntity

                            ATFM_SetupFirstTodo ->
                                inboxEntity

                            ATFM_AddByFocusInEntity ->
                                model.focusInEntity
                in
                    Stores.updateTodo
                        (case referenceEntity of
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
                        >> Return.map (Stores.setFocusInEntityFromTodoId todoId)
            )
