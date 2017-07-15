module Update.ExclusiveMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(GroupEntity, TodoEntity), GroupEntityType(ContextEntity, ProjectEntity), createContextEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(GDFM_Add, GDFM_Edit))
import GroupDoc.Types exposing (GroupDocType(ContextGroupDoc, ProjectGroupDoc))
import Model exposing (commonMsg)
import Msg exposing (..)
import Return exposing (andThen, map)
import Store
import Stores
import Todo
import Todo.FormTypes exposing (AddTodoFormMode(ATFM_AddToInbox, ATFM_AddWithFocusInEntityAsReference, ATFM_SetupFirstTodo), EditTodoFormMode(ETFM_EditTodoReminder, ETFM_EditTodoText), TodoForm, TodoFormMode(TFM_Add, TFM_Edit))
import Todo.Types exposing (TodoAction(TA_CopyProjectAndContextId, TA_SetContext, TA_SetProject, TA_SetScheduleFromMaybeTime, TA_SetText))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (..)
import X.Record exposing (..)
import X.Return


update :
    (AppMsg -> ReturnF)
    -> ExclusiveModeMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode
                |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        OnSaveExclusiveModeForm ->
            X.Return.with .editMode saveExclusiveModeForm
                >> update andThenUpdate OnSetExclusiveModeToNoneAndTryRevertingFocus


exclusiveMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setExclusiveMode : ExclusiveMode -> ModelF
setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")


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
