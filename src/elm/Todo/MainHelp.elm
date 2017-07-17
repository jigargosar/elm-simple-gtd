port module Todo.MainHelp exposing (..)

import Context
import Document
import Document.Types exposing (DocId, getDocId)
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd)
import Entity.Types exposing (Entity(..), EntityListViewType(ContextsView), GroupEntityType(..))
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import Model.TodoStore exposing (findTodoById)
import Stores
import Todo.Form
import Todo.FormTypes exposing (..)
import Todo.MainHelpPort exposing (..)
import Todo.Notification.Model
import Todo.Notification.Types
import Types exposing (AppModel)
import X.Record as Record exposing (overT2, set)
import X.Return exposing (rAndThenMaybe, returnWith)
import X.Time
import Notification
import Return exposing (andThen, command, map)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker as Tracker
import Todo.Types exposing (TodoAction(..))
import X.Function exposing (applyMaybeWith)


type alias SubModel =
    AppModel


type alias SubReturn msg =
    Return.Return msg SubModel



--type alias SubReturn msg model =
--    Return.Return msg (SubModel model)


type alias SubReturnF msg =
    SubReturn msg -> SubReturn msg


type alias Config msg =
    { switchToContextsView : SubReturnF msg
    , setFocusInEntityWithTodoId : DocId -> SubReturnF msg
    , setFocusInEntity : Entity -> SubReturnF msg
    , closeNotification : String -> SubReturnF msg
    , afterTodoUpdate : SubReturnF msg
    , setXMode : ExclusiveMode -> SubReturnF msg
    }


onSaveTodoForm form =
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


inboxEntity =
    Entity.Types.createContextEntity Context.null


saveAddTodoForm : AddTodoFormMode -> TodoForm -> SubModel -> SubReturn msg
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
        config.setXMode xMode
            >> Return.command
                (case action of
                    Todo.FormTypes.SetTodoMenuState _ ->
                        autoFocusInputCmd

                    _ ->
                        Cmd.none
                )


onStartEditingTodo config todo editFormMode =
    let
        createXMode model =
            Todo.Form.createEditTodoForm editFormMode model.now todo |> XMTodoForm

        positionPopup idPrefix =
            DomPorts.positionPopupMenu (idPrefix ++ getDocId todo)
    in
        X.Return.returnWith createXMode config.setXMode
            >> command
                (case editFormMode of
                    ETFM_EditTodoText ->
                        autoFocusInputCmd

                    ETFM_EditTodoContext ->
                        positionPopup "#edit-context-button-"

                    ETFM_EditTodoProject ->
                        positionPopup "#edit-project-button-"

                    ETFM_EditTodoReminder ->
                        positionPopup "#edit-schedule-button-"
                )


onStartAddingTodo config addFormMode =
    -- todo: think about merging 4 messages into one.
    let
        createXMode model =
            Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
    in
        X.Return.returnWith createXMode config.setXMode
            >> autoFocusInputRCmd


onStopRunningTodo =
    mapSet timeTracker Tracker.none


onGotoRunningTodo : Config msg -> SubReturnF msg
onGotoRunningTodo config =
    returnWith identity (gotoRunningTodo config)


onRunningNotificationResponse config res =
    let
        todoId =
            res.data.id
    in
        (case res.action of
            "stop" ->
                onStopRunningTodo

            "continue" ->
                identity

            _ ->
                onGotoRunningTodo config
        )
            >> config.closeNotification todoId


onReminderNotificationClicked notif =
    let
        { action, data } =
            notif

        todoId =
            data.id
    in
        if action == "mark-done" then
            Return.andThen (Stores.updateTodo TA_MarkDone todoId)
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
                    X.Time.toHHMMSSMin (info.elapsedTime)
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


gotoRunningTodo : Config msg -> AppModel -> SubReturnF msg
gotoRunningTodo config model =
    Tracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithId config model
        ?= identity


gotoTodoWithId : Config msg -> AppModel -> DocId -> SubReturnF msg
gotoTodoWithId config model todoId =
    let
        maybeTodoEntity =
            Stores.createEntityListForCurrentView model
                |> List.find
                    (\entity ->
                        case entity of
                            Entity.Types.TodoEntity doc ->
                                Document.hasId todoId doc

                            _ ->
                                False
                    )
    in
        maybeTodoEntity
            |> Maybe.unpack
                (\_ ->
                    config.setFocusInEntityWithTodoId todoId
                        >> config.switchToContextsView
                )
                config.setFocusInEntity


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.Notification.Model.initialView todo }


reminderOverlayAction : Todo.Notification.Model.Action -> SubReturnF msg
reminderOverlayAction action =
    returnWith identity
        (\model ->
            case model.reminderOverlay of
                Todo.Notification.Types.Active activeView todoDetails ->
                    onActive todoDetails action

                _ ->
                    identity
        )


onActive :
    Todo.Notification.Types.TodoDetails
    -> Todo.Notification.Model.Action
    -> SubReturnF msg
onActive todoDetails action =
    let
        todoId =
            todoDetails.id
    in
        case action of
            Todo.Notification.Model.Dismiss ->
                andThen (Stores.updateTodo (TA_TurnReminderOff) todoId)
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
                andThen (Stores.updateTodo TA_MarkDone todoId)
                    >> map removeReminderOverlay
                    >> Return.command (Notification.closeNotification todoId)


snoozeTodoWithOffset snoozeOffset todoId model =
    let
        time =
            Todo.Notification.Model.addSnoozeOffset model.now snoozeOffset
    in
        model
            |> Stores.updateTodo (time |> TA_SnoozeTill) todoId
            >> Tuple.mapFirst removeReminderOverlay


removeReminderOverlay model =
    { model | reminderOverlay = Todo.Notification.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.Notification.Model.snoozeView details }
