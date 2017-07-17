module Update.ExclusiveMode exposing (..)

import Context
import Document.Types exposing (getDocId)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(GDFM_Add, GDFM_Edit))
import GroupDoc.Types exposing (GroupDocType(..))
import Msg.ExclusiveMode exposing (ExclusiveModeMsg(..))
import Return exposing (andThen, map)
import Stores
import Todo
import Todo.FormTypes exposing (..)
import Todo.Types exposing (..)
import X.Record exposing (..)
import X.Return exposing (returnWith)


{- update :
   AndThenUpdate
   -> ExclusiveModeMsg
   -> ReturnF
-}


update config msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> config.focusEntityList

        OnSaveExclusiveModeForm ->
            returnWith .editMode saveExclusiveModeForm
                >> update config OnSetExclusiveModeToNoneAndTryRevertingFocus


exclusiveMode =
    fieldLens .editMode (\s b -> { b | editMode = s })



--setExclusiveMode : ExclusiveMode -> ModelF


setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


saveExclusiveModeForm exMode =
    case exMode of
        XMGroupDocForm form ->
            -- todo: cleanup and move
            let
                update fn =
                    fn form.id (GroupDoc.setName form.name)
                        |> andThen
            in
                case form.groupDocType of
                    ContextGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertContext form.name

                            GDFM_Edit ->
                                update Stores.updateContext

                    ProjectGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                Stores.insertProject form.name

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



--saveAddTodoForm : AddTodoFormMode -> TodoForm -> ModelReturnF


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
