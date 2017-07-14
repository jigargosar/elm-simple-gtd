module Update.ExMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(..), GroupEntityType(..), createContextEntity)
import ExclusiveMode.Types exposing (..)
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(..))
import GroupDoc.Types exposing (GroupDocType(..))
import Msg
import Project
import Return exposing (andThen, map)
import Store
import Todo
import Todo.Form
import Todo.Form
import Todo.FormTypes exposing (..)
import Stores
import Todo.Types exposing (TodoAction(..))
import Tuple2
import Types exposing (ModelReturnF)
import X.Record exposing (over, overT2)
import X.Return


onSaveExclusiveModeForm andThenUpdate =
    X.Return.with .editMode saveExclusiveModeForm
        >> andThenUpdate Msg.OnDeactivateEditingMode


saveExclusiveModeForm exMode =
    case exMode of
        XMGroupDocForm form ->
            -- todo: cleanup and move
            let
                update fn =
                    fn form.id (GroupDoc.setName form.name)
                        |> andThen

                insert store updateFn =
                    andThen
                        (\model ->
                            overT2 store (Store.insert (GroupDoc.init form.name model.now)) model
                                |> (\( gd, model ) -> updateFn (getDocId gd) identity model)
                        )
            in
                case form.groupDocType of
                    ContextGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                insert Stores.contextStore Stores.updateContext

                            GDFM_Edit ->
                                update Stores.updateContext

                    ProjectGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                insert Stores.projectStore Stores.updateProject

                            GDFM_Edit ->
                                update Stores.updateProject

        XMTodoForm form ->
            -- todo move to TodoStore update
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
