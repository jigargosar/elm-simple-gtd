module Update.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), GroupEntityType(..))
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
                TFT_Edit form ->
                    let
                        updateTodo action =
                            Stores.updateTodo action form.id model
                    in
                        case form.etfMode of
                            ETFM_EditTodoText ->
                                updateTodo (TA_SetText form.name)

                            ETFM_EditTodoReminder ->
                                updateTodo (TA_SetScheduleFromMaybeTime (Todo.Form.computeMaybeTime form))

                            _ ->
                                model |> Return.singleton

                TFT_NONE ->
                    model |> Return.singleton

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
    Stores.insertTodo (Todo.init model.now form.text) model
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
