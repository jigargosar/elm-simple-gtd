module Update.Todo exposing (..)

import Data.TodoDoc as TodoDoc exposing (TodoAction(..), TodoDoc, TodoStore)
import Document exposing (..)
import DomPorts
import Entity exposing (..)
import EntityId
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import GroupDoc exposing (GroupDocStore)
import Models.Stores
import Models.TodoDocStore as TodoDocStore
import Notification exposing (Response)
import Ports.Todo
import Return
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo.Form
import Todo.FormTypes exposing (..)
import Todo.ReminderOverlay.Model
import Todo.ReminderOverlay.Types exposing (TodoReminderOverlayModel)
import Toolkit.Operators exposing (..)
import X.Function exposing (applyMaybeWith)
import X.Function.Infix exposing (..)
import X.Predicate
import X.Record as Record exposing (..)
import X.Return exposing (..)
import X.Time


type TodoMsg
    = OnReminderNotificationClicked Notification.TodoNotificationEvent
    | OnProcessPendingNotificationCronTick
    | UpdateTodoOrAllSelected__ DocId TodoAction
    | UpdateTodo__ DocId TodoAction
    | OnTodoReminderOverlayAction Todo.ReminderOverlay.Model.Action
    | OnStartAddingTodo AddTodoFormMode
    | OnStartEditingTodo TodoDoc EditTodoFormMode
    | OnUpdateTodoFormAction TodoForm TodoFormAction
    | OnSaveTodoForm TodoForm


onReminderOverlayActionMsg =
    OnTodoReminderOverlayAction



-- form add


onStartAdding__ =
    OnStartAddingTodo


onStartAddingTodoToInbox =
    onStartAdding__ ATFM_AddToInbox


onStartAddingTodoWithFocusInEntityAsReference =
    ATFM_AddWithFocusInEntityAsReference >> onStartAdding__


onStartSetupAddTodo =
    onStartAdding__ ATFM_SetupFirstTodo



-- form edit


onStartEditingMsg__ editMode todo =
    OnStartEditingTodo todo editMode


onStartEditingTodoMsg =
    onStartEditingTodoTextMsg


onStartEditingTodoTextMsg =
    onStartEditingMsg__ ETFM_EditTodoText


onStartEditingTodoContextMsg =
    onStartEditingMsg__ ETFM_EditTodoContext


onStartEditingTodoProjectMsg =
    onStartEditingMsg__ ETFM_EditTodoProject


onStartEditingReminderMsg =
    onStartEditingMsg__ ETFM_EditTodoSchedule



-- form update


onUpdateFormActionMsg__ setterAction form =
    setterAction >> OnUpdateTodoFormAction form


onSetTodoFormMenuStateMsg =
    onUpdateFormActionMsg__ SetTodoMenuState


onSetTodoFormReminderDateMsg =
    onUpdateFormActionMsg__ SetTodoReminderDate


onSetTodoFormReminderTimeMsg =
    onUpdateFormActionMsg__ SetTodoReminderTime


onSetTodoFormTextMsg =
    onUpdateFormActionMsg__ SetTodoText



-- direct


onToggleDeletedMsg id =
    UpdateTodo__ id TA_ToggleDeleted


onToggleDeletedAndMaybeSelectionMsg id =
    UpdateTodoOrAllSelected__ id TA_ToggleDeleted


onToggleDoneAndMaybeSelectionMsg id =
    UpdateTodoOrAllSelected__ id TA_ToggleDone


onSetProjectAndMaybeSelectionMsg id =
    TA_SetProject
        >> UpdateTodoOrAllSelected__ id


onSetContextAndMaybeSelectionMsg id =
    TA_SetContext
        >> UpdateTodoOrAllSelected__ id


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : GroupDocStore
        , contextStore : GroupDocStore
        , reminderOverlay : TodoReminderOverlayModel
        , selectedEntityIdSet : Set DocId
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | setFocusInEntityWithEntityId : EntityId -> msg
        , revertExclusiveModeMsg : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , goToEntityIdCmd : EntityId -> Cmd msg
        , recomputeEntityListCursorAfterStoreUpdated : msg
    }


update :
    Config msg a
    -> Time.Time
    -> TodoMsg
    -> SubReturnF msg model
update config now msg =
    case msg of
        OnReminderNotificationClicked notificationEvent ->
            onReminderNotificationClicked config now notificationEvent

        OnProcessPendingNotificationCronTick ->
            returnAndThenMaybe
                (findAndSnoozeOverDueTodo config now >>? andThen showReminderNotificationCmd)

        UpdateTodoOrAllSelected__ todoId action ->
            (updateTodoAndMaybeAlsoSelected config action now todoId |> andThen)
                >> returnMsgAsCmd config.revertExclusiveModeMsg

        UpdateTodo__ todoId action ->
            (updateAllTodos config action now (Set.singleton todoId) |> andThen)
                >> returnMsgAsCmd config.revertExclusiveModeMsg

        OnTodoReminderOverlayAction action ->
            reminderOverlayAction config action now

        OnStartAddingTodo addFormMode ->
            onStartAddingTodo config addFormMode

        OnStartEditingTodo todo editFormMode ->
            onStartEditingTodo config now todo editFormMode

        OnUpdateTodoFormAction form action ->
            onUpdateTodoFormAction config form action

        OnSaveTodoForm form ->
            onSaveTodoForm config form now
                >> returnMsgAsCmd config.revertExclusiveModeMsg


findAndUpdateAllTodos :
    Config msg a
    -> (TodoDoc -> Bool)
    -> TodoAction
    -> Time
    -> SubModel model
    -> SubReturn msg model
findAndUpdateAllTodos config findFn action now model =
    let
        updateFn =
            TodoDoc.update action
    in
    Store.updateAndPersist findFn now updateFn model.todoStore
        |> Tuple.mapFirst (setIn model TodoDocStore.todoStoreL)
        |> returnMsgAsCmd config.recomputeEntityListCursorAfterStoreUpdated


updateAll :
    Config msg a
    -> Set DocId
    -> TodoAction
    -> Time
    -> SubModel model
    -> SubReturn msg model
updateAll config docIdSet action now model =
    let
        updateFn =
            TodoDoc.update action
    in
    Store.updateAndPersist (always False) now updateFn model.todoStore
        |> Tuple.mapFirst (setIn model TodoDocStore.todoStoreL)
        |> returnMsgAsCmd config.recomputeEntityListCursorAfterStoreUpdated


updateTodo config action now todoId =
    findAndUpdateAllTodos config (Document.hasId todoId) action now


updateTodoWithMaybeAction config maybeAction now todoId =
    maybeAction ?|> updateTodo config # now # todoId ?= Return.singleton


updateAllTodos config action now idSet model =
    findAndUpdateAllTodos config (Document.getId >> Set.member # idSet) action now model


updateTodoAndMaybeAlsoSelected config action now todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
    model |> updateAllTodos config action now idSet


findAndSnoozeOverDueTodo config now model =
    let
        snooze todoId =
            updateTodo config (TA_AutoSnooze now) now todoId model
                |> (\( model, cmd ) ->
                        TodoDocStore.findTodoById todoId model ?|> (\todo -> ( ( todo, model ), cmd ))
                   )
    in
    Store.findBy
        (X.Predicate.all
            [ TodoDoc.isReminderOverdue now
            , Models.Stores.allTodoGroupDocActivePredicate model
            ]
        )
        model.todoStore
        ?+> (Document.getId >> snooze)


onSaveTodoForm config form now =
    case form.mode of
        TFM_Edit editMode ->
            let
                updateTodoHelp action =
                    updateTodo config action now form.id
                        |> andThen
            in
            case editMode of
                ETFM_EditTodoText ->
                    updateTodoHelp <| TA_SetText form.text

                ETFM_EditTodoSchedule ->
                    updateTodoHelp <| TA_SetScheduleFromMaybeTime form.maybeComputedTime

                _ ->
                    identity

        TFM_Add addMode ->
            saveAddTodoForm config addMode form now |> andThen


insertTodo constructWithId =
    overT2 TodoDocStore.todoStoreL (Store.insert constructWithId)


saveAddTodoForm :
    Config msg a
    -> AddTodoFormMode
    -> TodoForm
    -> Time
    -> SubModel model
    -> SubReturn msg model
saveAddTodoForm config addMode form now model =
    insertTodo (TodoDoc.init now form.text) model
        |> Tuple.mapFirst Document.getId
        |> uncurry
            (\todoId ->
                let
                    inboxEntityId =
                        EntityId.fromContext GroupDoc.nullContext

                    referenceEntityId =
                        case addMode of
                            ATFM_AddToInbox ->
                                inboxEntityId

                            ATFM_SetupFirstTodo ->
                                inboxEntityId

                            ATFM_AddWithFocusInEntityAsReference maybeEntityIdAtCursorOld ->
                                maybeEntityIdAtCursorOld
                                    ?= inboxEntityId

                    maybeAction =
                        case referenceEntityId of
                            TodoEntityId todoId ->
                                TodoDocStore.findTodoById todoId model
                                    ?|> TA_CopyProjectAndContextId

                            ContextEntityId contextId ->
                                TA_SetContextId contextId |> Just

                            ProjectEntityId projectId ->
                                TA_SetProjectId projectId |> Just
                in
                updateTodoWithMaybeAction config maybeAction now todoId
                    >> returnMsgAsCmd config.recomputeEntityListCursorAfterStoreUpdated
             --                    >> setFocusInEntityWithTodoId config todoId
            )


mapOver =
    Record.over >>> Return.map


mapSet =
    Record.set >>> Return.map


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


timeTracker =
    Record.fieldLens .timeTracker (\s b -> { b | timeTracker = s })


onUpdateTodoFormAction config form action =
    let
        xMode =
            Todo.Form.updateTodoForm action form |> XMTodoForm
    in
    config.onSetExclusiveMode xMode |> returnMsgAsCmd


onStartEditingTodo config now todo editFormMode =
    let
        createXMode model =
            Todo.Form.createEditTodoForm editFormMode now todo |> XMTodoForm

        positionPopup idPrefix =
            DomPorts.positionPopupMenu (idPrefix ++ Document.getId todo)
    in
    X.Return.returnWith createXMode (config.onSetExclusiveMode >> returnMsgAsCmd)
        >> command
            (case editFormMode of
                ETFM_EditTodoText ->
                    Cmd.none

                ETFM_EditTodoContext ->
                    positionPopup "#edit-context-button-"

                ETFM_EditTodoProject ->
                    positionPopup "#edit-project-button-"

                ETFM_EditTodoSchedule ->
                    positionPopup "#edit-schedule-button-"
            )


onStartAddingTodo config addFormMode =
    let
        createXMode model =
            Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
    in
    X.Return.returnWith createXMode (config.onSetExclusiveMode >> returnMsgAsCmd)


onReminderNotificationClicked config now notificationEvent =
    let
        { action, data } =
            notificationEvent

        todoId =
            data.id
    in
    if action == "mark-done" then
        Return.andThen (updateTodo config TA_MarkDone now todoId)
            >> command (Notification.closeNotification todoId)
    else
        map (showReminderOverlayForTodoId todoId)



-->> command (config.goToEntityIdCmd (EntityId.fromTodoDocId todoId))


showReminderNotificationCmd ( todo, model ) =
    let
        createNotification =
            let
                id =
                    Document.getId todo
            in
            { title = TodoDoc.getText todo, tag = id, data = { id = id } }

        cmds =
            [ createNotification
                |> Ports.Todo.showTodoReminderNotification
            , Notification.startAlarm ()
            ]
    in
    model ! cmds



-- todo: use this template to create reminder notification


showRunningNotificationCmd ( maybeTrackerInfo, model ) =
    let
        createRequest info todo =
            let
                todoId =
                    Document.getId todo

                formattedDuration =
                    X.Time.toHHMMSSMin info.elapsedTime
            in
            { tag = todoId
            , title = "You have been working for " ++ formattedDuration
            , body = TodoDoc.getText todo
            , actions =
                [ { title = "Continue", action = "continue" }
                , { title = "Stop", action = "stop" }
                ]
            , data =
                { id = todoId
                , notificationClickedPort = "onRunningTodoNotificationClicked"
                , skipFocusActionList = [ "continue" ]
                }
            }
    in
    maybeTrackerInfo
        ?+> (\info -> TodoDocStore.findTodoById info.todoId model ?|> createRequest info)
        |> maybeMapToCmd Ports.Todo.showRunningTodoNotification


setFocusInEntityWithTodoId config =
    createTodoEntityId >> config.setFocusInEntityWithEntityId >> returnMsgAsCmd


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (TodoDocStore.findTodoById todoId)
        setReminderOverlayToInitialView


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.initialView todo }


reminderOverlayAction : Config msg a -> Todo.ReminderOverlay.Model.Action -> Time -> SubReturnF msg model
reminderOverlayAction config action now =
    returnWithMaybe1 .reminderOverlay (onActive config action now)


onActive :
    Config msg a
    -> Todo.ReminderOverlay.Model.Action
    -> Time
    -> Todo.ReminderOverlay.Types.InnerModel
    -> SubReturnF msg model
onActive config action now ( _, todoDetails ) =
    let
        todoId =
            todoDetails.id
    in
    case action of
        Todo.ReminderOverlay.Model.Dismiss ->
            andThen (updateTodo config TA_TurnReminderOff now todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)

        Todo.ReminderOverlay.Model.ShowSnoozeOptions ->
            map (setReminderOverlayToSnoozeView todoDetails)

        Todo.ReminderOverlay.Model.SnoozeTill snoozeOffset ->
            Return.andThen (snoozeTodoWithOffset config snoozeOffset now todoId)
                >> Return.command (Notification.closeNotification todoId)

        Todo.ReminderOverlay.Model.Close ->
            map removeReminderOverlay

        Todo.ReminderOverlay.Model.MarkDone ->
            andThen (updateTodo config TA_MarkDone now todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)


snoozeTodoWithOffset config snoozeOffset now todoId model =
    let
        time =
            Todo.ReminderOverlay.Model.addSnoozeOffset now snoozeOffset
    in
    model
        |> updateTodo config (time |> TA_SnoozeTill) now todoId
        >> Tuple.mapFirst removeReminderOverlay


removeReminderOverlay model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.snoozeView details }
