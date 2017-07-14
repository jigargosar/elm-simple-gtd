module Update.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), GroupEntityType(..), createContextEntity)
import ExclusiveMode.Types exposing (..)
import Msg
import Project
import Return exposing (andThen, map)
import Todo
import Todo.Form
import Todo.Form
import Todo.FormTypes exposing (..)
import Stores
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelReturnF)
import X.Return


onSaveExclusiveModeForm andThenUpdate =
    X.Return.with .editMode saveExclusiveModeForm
        >> andThenUpdate Msg.OnDeactivateEditingMode


saveExclusiveModeForm exMode =
    case exMode of
        XMEditContext form ->
            Stores.updateContext form.id (Context.setName form.name)
                |> andThen

        XMEditProject form ->
            Stores.updateProject form.id
                (Project.setName form.name)
                |> andThen

        XMTodo t ->
            -- todo move to TodoStore update
            case t of
                TXM_Form form ->
                    case form.mode of
                        TFM_Edit editMode ->
                            let
                                updateTodo action =
                                    Stores.updateTodo action form.id
                                        |> andThen
                            in
                                case editMode of
                                    ETFM_EditTodoText ->
                                        updateTodo <| TA_SetText form.text

                                    ETFM_EditTodoReminder ->
                                        updateTodo <| TA_SetScheduleFromMaybeTime form.maybeComputedTime

                                    _ ->
                                        identity

                        TFM_Add addMode ->
                            saveAddTodoForm addMode form |> andThen

        XMEditSyncSettings form ->
            (\model -> { model | pouchDBRemoteSyncURI = form.uri })
                |> map

        _ ->
            identity


inboxEntity =
    createContextEntity Context.null


saveAddTodoForm : AddTodoFormMode -> TodoForm -> ModelReturnF
saveAddTodoForm addMode form model =
    Stores.insertTodo (Todo.init model.now form.text) model
        |> Tuple.mapFirst getDocId
        |> uncurry
            (\todoId ->
                let
                    referenceEntity =
                        case addMode of
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
                        >> Return.map (Stores.setFocusInEntityWithTodoId todoId)
            )
