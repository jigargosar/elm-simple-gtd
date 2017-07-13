module Update.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), GroupEntityType(..), createContextEntity)
import ExclusiveMode.Types exposing (..)
import Project
import Return exposing (andThen, map)
import Todo
import Todo.Form
import Todo.Form
import Todo.FormTypes exposing (..)
import Stores
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelReturnF)


saveCurrentForm editMode =
    case editMode of
        XMEditContext form ->
            Stores.updateContext form.id (Context.setName form.name)
                |> andThen

        XMEditProject form ->
            Stores.updateProject form.id
                (Project.setName form.name)
                |> andThen

        XMTodo t ->
            case t of
                EditTodoForm form ->
                    let
                        updateTodo action =
                            Stores.updateTodo action form.id
                                |> andThen
                    in
                        case form.etfMode of
                            ETFM_EditTodoText ->
                                updateTodo <| TA_SetText form.text

                            ETFM_EditTodoReminder ->
                                updateTodo <| TA_SetScheduleFromMaybeTime form.maybeComputedTime

                            _ ->
                                identity

                NoTodoForm ->
                    identity

                AddTodoForm form ->
                    saveNewTodoForm form |> andThen

        XMEditSyncSettings form ->
            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
                |> map

        _ ->
            identity


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

                            ATFM_AddWithFocusInEntityAsReference ->
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
