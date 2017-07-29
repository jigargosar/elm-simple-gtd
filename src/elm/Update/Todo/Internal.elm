port module Update.Todo.Internal exposing (..)

import Context
import Document exposing (DocId)
import DomPorts
import Entity.Types exposing (..)
import EntityListCursor exposing (HasEntityListCursor)
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import Model.Todo exposing (findTodoById, todoStore)
import Notification
import Ports.Todo exposing (..)
import Return
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.FormTypes exposing (..)
import Todo.Notification.Model
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.TimeTracker as Tracker
import Todo.Types exposing (TodoAction(..), TodoStore)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (applyMaybeWith)
import X.Function.Infix exposing (..)
import X.Record as Record exposing (overReturn, overT2, set)
import X.Return exposing (..)
import X.Time


type alias SubModel model =
    HasEntityListCursor
        { model
            | now : Time
            , todoStore : TodoStore
            , reminderOverlay : TodoReminderOverlayModel
            , timeTracker : Tracker.Model
            , selectedEntityIdSet : Set DocId
        }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | setFocusInEntityWithEntityId : EntityId -> msg
        , revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , bringEntityIdInViewMsg : EntityId -> msg
    }


findAndUpdateAllTodos findFn action model =
    let
        updateFn =
            Todo.update action
    in
    overReturn todoStore (Store.updateAndPersist findFn model.now updateFn) model



--updateTodo : TodoAction -> DocId -> ModelReturnF


updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action


updateTodoWithMaybeAction maybeAction todoId =
    maybeAction ?|> updateTodo # todoId ?= Return.singleton



--    findAndUpdateAllTodos (Document.hasId todoId) action
--updateAllTodos : TodoAction -> Document.IdSet -> ModelReturnF


updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model


updateTodoAndMaybeAlsoSelected action todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
    model |> updateAllTodos action idSet


findTodoWithOverDueReminder model =
    model.todoStore |> Store.findBy (Todo.isReminderOverdue model.now)



--findAndSnoozeOverDueTodo : AppModel -> Maybe ( ( TodoDoc, AppModel ), Cmd AppMsg )


findAndSnoozeOverDueTodo model =
    let
        snooze todoId =
            updateTodo (TA_AutoSnooze model.now) todoId model
                |> (\( model, cmd ) ->
                        findTodoById todoId model ?|> (\todo -> ( ( todo, model ), cmd ))
                   )
    in
    Store.findBy (Todo.isReminderOverdue model.now) model.todoStore
        ?+> (Document.getId >> snooze)


onSaveTodoForm config form =
    case form.mode of
        TFM_Edit editMode ->
            let
                updateTodoHelp action =
                    updateTodo action form.id
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
            saveAddTodoForm config addMode form |> andThen



--insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )


insertTodo constructWithId =
    overT2 todoStore (Store.insert constructWithId)


saveAddTodoForm :
    Config msg a
    -> AddTodoFormMode
    -> TodoForm
    -> SubModel model
    -> SubReturn msg model
saveAddTodoForm config addMode form model =
    insertTodo (Todo.init model.now form.text) model
        |> Tuple.mapFirst Document.getId
        |> uncurry
            (\todoId ->
                let
                    inboxEntityId =
                        Entity.Types.createContextEntityId Context.nullId

                    referenceEntityId =
                        case addMode of
                            ATFM_AddToInbox ->
                                inboxEntityId

                            ATFM_SetupFirstTodo ->
                                inboxEntityId

                            ATFM_AddWithFocusInEntityAsReference ->
                                EntityListCursor.getMaybeEntityIdAtCursor model
                                    ?= inboxEntityId

                    maybeAction =
                        case referenceEntityId of
                            TodoId todoId ->
                                Model.Todo.findTodoById todoId model
                                    ?|> TA_CopyProjectAndContextId

                            ContextId contextId ->
                                TA_SetContextId contextId |> Just

                            ProjectId projectId ->
                                TA_SetProjectId projectId |> Just
                in
                updateTodoWithMaybeAction maybeAction todoId
                    >> setFocusInEntityWithTodoId config todoId
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


onStartEditingTodo config todo editFormMode =
    let
        createXMode model =
            Todo.Form.createEditTodoForm editFormMode model.now todo |> XMTodoForm

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



--            >> autoFocusInputRCmd


onStopRunningTodoMsg =
    mapSet timeTracker Tracker.none


onGotoRunningTodo : Config msg a -> SubReturnF msg model
onGotoRunningTodo config =
    returnWith identity (gotoRunningTodo config)


onRunningNotificationResponse : Config msg a -> Notification.Response -> SubReturnF msg model
onRunningNotificationResponse config res =
    let
        todoId =
            res.data.id
    in
    (case res.action of
        "stop" ->
            onStopRunningTodoMsg

        "continue" ->
            identity

        _ ->
            onGotoRunningTodo config
    )
        >> command (Notification.closeNotification todoId)


onReminderNotificationClicked notif =
    let
        { action, data } =
            notif

        todoId =
            data.id
    in
    if action == "mark-done" then
        Return.andThen (updateTodo TA_MarkDone todoId)
            >> command (Notification.closeNotification todoId)
    else
        map (showReminderOverlayForTodoId todoId)


onAfterUpsertTodo todo =
    map
        (\model ->
            let
                isTrackerTodoInactive =
                    Todo.isInActive todo
                        && Tracker.isTrackingTodo todo model.timeTracker
            in
            if isTrackerTodoInactive then
                set timeTracker Tracker.none model
            else
                model
        )


showReminderNotificationCmd ( todo, model ) =
    let
        createNotification =
            let
                id =
                    Document.getId todo
            in
            { title = Todo.getText todo, tag = id, data = { id = id } }

        cmds =
            [ createNotification
                |> showTodoReminderNotification
            , Notification.startAlarm ()
            ]
    in
    model ! cmds


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
            , body = Todo.getText todo
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
        ?+> (\info -> findTodoById info.todoId model ?|> createRequest info)
        |> maybeMapToCmd showRunningTodoNotification


updateTimeTracker now =
    overT2 timeTracker (Tracker.updateNextAlarmAt now)
        >> apply2 ( Tuple.second, showRunningNotificationCmd )
        |> andThen


gotoRunningTodo : Config msg a -> SubModel model -> SubReturnF msg model
gotoRunningTodo config model =
    Tracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithId config model
        ?= identity


gotoTodoWithId : Config msg a -> SubModel model -> DocId -> SubReturnF msg model
gotoTodoWithId config model todoId =
    config.bringEntityIdInViewMsg (createTodoEntityId todoId)
        |> returnMsgAsCmd


setFocusInEntityWithTodoId config =
    createTodoEntityId >> config.setFocusInEntityWithEntityId >> returnMsgAsCmd


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        setReminderOverlayToInitialView


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.Notification.Model.initialView todo }


reminderOverlayAction : Todo.Notification.Model.Action -> SubReturnF msg model
reminderOverlayAction action =
    returnWithMaybe1 .reminderOverlay (onActive action)


onActive :
    Todo.Notification.Model.Action
    -> Todo.Notification.Types.InnerModel
    -> SubReturnF msg model
onActive action ( _, todoDetails ) =
    let
        todoId =
            todoDetails.id
    in
    case action of
        Todo.Notification.Model.Dismiss ->
            andThen (updateTodo TA_TurnReminderOff todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)

        Todo.Notification.Model.ShowSnoozeOptions ->
            map (setReminderOverlayToSnoozeView todoDetails)

        Todo.Notification.Model.SnoozeTill snoozeOffset ->
            Return.andThen (snoozeTodoWithOffset snoozeOffset todoId)
                >> Return.command (Notification.closeNotification todoId)

        Todo.Notification.Model.Close ->
            map removeReminderOverlay

        Todo.Notification.Model.MarkDone ->
            andThen (updateTodo TA_MarkDone todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)


snoozeTodoWithOffset snoozeOffset todoId model =
    let
        time =
            Todo.Notification.Model.addSnoozeOffset model.now snoozeOffset
    in
    model
        |> updateTodo (time |> TA_SnoozeTill) todoId
        >> Tuple.mapFirst removeReminderOverlay


removeReminderOverlay model =
    { model | reminderOverlay = Todo.Notification.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.Notification.Model.snoozeView details }
