port module Todo.MainHelp exposing (..)

import Context
import Document
import Document.Types exposing (DocId, getDocId)
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd)
import Entity.Types exposing (EntityListViewType(ContextsView))
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import Model.ViewType
import Msg
import ReturnTypes exposing (Return, ReturnF)
import Stores exposing (findTodoById)
import Todo.Form
import Todo.FormTypes exposing (EditTodoFormMode(..))
import Todo.MainHelpPort exposing (..)
import Todo.Msg exposing (TodoMsg(ShowReminderOverlayForTodoId))
import Todo.Notification.Model
import Todo.Notification.Types
import TodoMsg
import Types exposing (AppModel)
import X.Record as Record exposing (set)
import X.Return exposing (rAndThenMaybe)
import X.Time
import Notification
import Return exposing (command, map)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.TimeTracker as Tracker
import Todo.Types exposing (TodoAction(TA_MarkDone, TA_SnoozeTill, TA_TurnReminderOff))
import X.Function exposing (applyMaybeWith)
import XMMsg


mapOver =
    Record.over >>> Return.map


mapSet =
    Record.set >>> Return.map


map =
    Return.map


command =
    Return.command


andThen =
    Return.andThen


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


timeTracker =
    Record.fieldLens .timeTracker (\s b -> { b | timeTracker = s })


onUpdateTodoFormAction andThenUpdate form action =
    let
        xm =
            Todo.Form.updateTodoForm action form |> XMTodoForm
    in
        andThenUpdate (XMMsg.onSetExclusiveMode xm)
            >> Return.command
                (case action of
                    Todo.FormTypes.SetTodoMenuState _ ->
                        autoFocusInputCmd

                    _ ->
                        Cmd.none
                )


onStartEditingTodo andThenUpdate todo editFormMode =
    let
        createXM model =
            Todo.Form.createEditTodoForm editFormMode model.now todo |> XMTodoForm

        positionPopup idPrefix =
            DomPorts.positionPopupMenu (idPrefix ++ getDocId todo)
    in
        X.Return.returnWith createXM (XMMsg.onSetExclusiveMode >> andThenUpdate)
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


onStartAddingTodo andThenUpdate addFormMode =
    -- todo: think about merging 4 messages into one.
    let
        createXM model =
            Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
    in
        X.Return.returnWith createXM (XMMsg.onSetExclusiveMode >> andThenUpdate)
            >> autoFocusInputRCmd


onRunningNotificationResponse andThenUpdate res =
    let
        todoId =
            res.data.id
    in
        (case res.action of
            "stop" ->
                andThenUpdate TodoMsg.onStopRunningTodo

            "continue" ->
                identity

            _ ->
                andThenUpdate TodoMsg.onGotoRunningTodo
        )
            >> andThenUpdate (Msg.OnCloseNotification todoId)


onReminderNotificationClicked andThenUpdate notif =
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
            todoId
                |> ShowReminderOverlayForTodoId
                >> Msg.OnTodoMsg
                >> andThenUpdate


onUpsertTodo todo =
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
            ?+> (\info -> Stores.findTodoById info.todoId model ?|> createRequest info)
            |> maybeMapToCmd showRunningTodoNotification


updateTimeTracker now =
    Record.overT2 timeTracker (Tracker.updateNextAlarmAt now)
        >> apply2 ( Tuple.second, showRunningNotificationCmd )
        |> andThen


gotoRunningTodo : (Msg.AppMsg -> ReturnF) -> AppModel -> Return
gotoRunningTodo andThenUpdate model =
    Tracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithId andThenUpdate model
        ?= Return.singleton model


gotoTodoWithId : (Msg.AppMsg -> ReturnF) -> AppModel -> DocId -> Return
gotoTodoWithId andThenUpdate model todoId =
    let
        maybeTodoEntity =
            Stores.getCurrentViewEntityList model
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
                    model
                        |> Stores.setFocusInEntityWithTodoId todoId
                        |> Return.singleton
                        |> andThenUpdate (Msg.switchToEntityListView ContextsView)
                )
                (\e -> Stores.setFocusInEntity e model |> Return.singleton)


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.Notification.Model.initialView todo }


inboxEntity =
    Entity.Types.createContextEntity Context.null


reminderOverlayAction action =
    Return.andThen
        (\model ->
            model
                |> case model.reminderOverlay of
                    Todo.Notification.Types.Active activeView todoDetails ->
                        let
                            todoId =
                                todoDetails.id
                        in
                            case action of
                                Todo.Notification.Model.Dismiss ->
                                    Stores.updateTodo (TA_TurnReminderOff) todoId
                                        >> Tuple.mapFirst removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.ShowSnoozeOptions ->
                                    setReminderOverlayToSnoozeView todoDetails
                                        >> Return.singleton

                                Todo.Notification.Model.SnoozeTill snoozeOffset ->
                                    Return.singleton
                                        >> Return.andThen (snoozeTodoWithOffset snoozeOffset todoId)
                                        >> Return.command (Notification.closeNotification todoId)

                                Todo.Notification.Model.Close ->
                                    removeReminderOverlay
                                        >> Return.singleton

                                Todo.Notification.Model.MarkDone ->
                                    Stores.updateTodo TA_MarkDone todoId
                                        >> Tuple.mapFirst removeReminderOverlay
                                        >> Return.command (Notification.closeNotification todoId)

                    _ ->
                        Return.singleton
        )


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
