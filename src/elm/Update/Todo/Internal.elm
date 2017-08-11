port module Update.Todo.Internal exposing (..)

import Data.TodoDoc exposing (..)
import Document exposing (..)
import DomPorts
import Entity exposing (..)
import EntityId
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import GroupDoc
import Models.TodoDocStore as TodoDocStore
import Notification
import Ports.Todo exposing (..)
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
import X.Record as Record exposing (overReturn, overT2, set)
import X.Return exposing (..)
import X.Time


type alias SubModel model =
    { model
        | todoStore : TodoStore
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
        , revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , goToEntityIdCmd : EntityId -> Cmd msg
    }


findAndUpdateAllTodos findFn action now model =
    let
        updateFn =
            Data.TodoDoc.update action
    in
    overReturn TodoDocStore.todoStore (Store.updateAndPersist findFn now updateFn) model


updateTodo action now todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action now


updateTodoWithMaybeAction maybeAction now todoId =
    maybeAction ?|> updateTodo # now # todoId ?= Return.singleton


updateAllTodos action now idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action now model


updateTodoAndMaybeAlsoSelected action now todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
    model |> updateAllTodos action now idSet


findAndSnoozeOverDueTodo now model =
    let
        snooze todoId =
            updateTodo (TA_AutoSnooze now) now todoId model
                |> (\( model, cmd ) ->
                        TodoDocStore.findTodoById todoId model ?|> (\todo -> ( ( todo, model ), cmd ))
                   )
    in
    Store.findBy (Data.TodoDoc.isReminderOverdue now) model.todoStore
        ?+> (Document.getId >> snooze)


onSaveTodoForm config form now =
    case form.mode of
        TFM_Edit editMode ->
            let
                updateTodoHelp action =
                    updateTodo action now form.id
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
    overT2 TodoDocStore.todoStore (Store.insert constructWithId)


saveAddTodoForm :
    Config msg a
    -> AddTodoFormMode
    -> TodoForm
    -> Time
    -> SubModel model
    -> SubReturn msg model
saveAddTodoForm config addMode form now model =
    insertTodo (Data.TodoDoc.init now form.text) model
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
                updateTodoWithMaybeAction maybeAction now todoId
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
        Return.andThen (updateTodo TA_MarkDone now todoId)
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
            { title = Data.TodoDoc.getText todo, tag = id, data = { id = id } }

        cmds =
            [ createNotification
                |> showTodoReminderNotification
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
            , body = Data.TodoDoc.getText todo
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
        |> maybeMapToCmd showRunningTodoNotification


setFocusInEntityWithTodoId config =
    createTodoEntityId >> config.setFocusInEntityWithEntityId >> returnMsgAsCmd


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (TodoDocStore.findTodoById todoId)
        setReminderOverlayToInitialView


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.initialView todo }


reminderOverlayAction : Todo.ReminderOverlay.Model.Action -> Time -> SubReturnF msg model
reminderOverlayAction action now =
    returnWithMaybe1 .reminderOverlay (onActive action now)


onActive :
    Todo.ReminderOverlay.Model.Action
    -> Time
    -> Todo.ReminderOverlay.Types.InnerModel
    -> SubReturnF msg model
onActive action now ( _, todoDetails ) =
    let
        todoId =
            todoDetails.id
    in
    case action of
        Todo.ReminderOverlay.Model.Dismiss ->
            andThen (updateTodo TA_TurnReminderOff now todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)

        Todo.ReminderOverlay.Model.ShowSnoozeOptions ->
            map (setReminderOverlayToSnoozeView todoDetails)

        Todo.ReminderOverlay.Model.SnoozeTill snoozeOffset ->
            Return.andThen (snoozeTodoWithOffset snoozeOffset now todoId)
                >> Return.command (Notification.closeNotification todoId)

        Todo.ReminderOverlay.Model.Close ->
            map removeReminderOverlay

        Todo.ReminderOverlay.Model.MarkDone ->
            andThen (updateTodo TA_MarkDone now todoId)
                >> map removeReminderOverlay
                >> Return.command (Notification.closeNotification todoId)


snoozeTodoWithOffset snoozeOffset now todoId model =
    let
        time =
            Todo.ReminderOverlay.Model.addSnoozeOffset now snoozeOffset
    in
    model
        |> updateTodo (time |> TA_SnoozeTill) now todoId
        >> Tuple.mapFirst removeReminderOverlay


removeReminderOverlay model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.ReminderOverlay.Model.snoozeView details }
