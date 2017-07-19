port module Update.Todo.Internal exposing (..)

import Context
import Document
import Document.Types exposing (DocId, getDocId)
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd)
import Entity.Types exposing (..)
import ExclusiveMode.Types exposing (ExclusiveMode(XMTodoForm))
import Lazy exposing (Lazy)
import Model.Todo exposing (findTodoById, todoStore)
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo.Form
import Todo.FormTypes exposing (..)
import Ports.Todo exposing (..)
import Todo.Notification.Model
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Tuple2
import X.Record as Record exposing (overT2, set)
import X.Return exposing (rAndThenMaybe, returnWith, returnWithMaybe1)
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
import Todo.Types exposing (TodoAction(..), TodoStore)
import X.Function exposing (applyMaybeWith)


type alias SubModel model =
    { model
        | now : Time
        , todoStore : TodoStore
        , reminderOverlay : TodoReminderOverlayModel
        , timeTracker : Tracker.Model
        , focusInEntity : Entity
        , selectedEntityIdSet : Set DocId
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config a msg model =
    { a
        | switchToContextsView : SubReturnF msg model
        , setFocusInEntityWithEntityId : EntityId -> SubReturnF msg model
        , setFocusInEntity : Entity -> SubReturnF msg model
        , closeNotification : String -> SubReturnF msg model
        , afterTodoUpdate : SubReturnF msg model
        , setXMode : ExclusiveMode -> SubReturnF msg model
        , currentViewEntityList : Lazy (List Entity)
    }


findAndUpdateAllTodos findFn action model =
    let
        updateFn =
            Todo.update action
    in
        overT2 todoStore (Store.updateAndPersist findFn model.now updateFn) model
            |> Tuple2.swap



--updateTodo : TodoAction -> DocId -> ModelReturnF


updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action



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


inboxEntity =
    Entity.Types.createContextEntity Context.null



--insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )


insertTodo constructWithId =
    overT2 todoStore (Store.insert (constructWithId))


saveAddTodoForm :
    Config a msg model
    -> AddTodoFormMode
    -> TodoForm
    -> SubModel model
    -> SubReturn msg model
saveAddTodoForm config addMode form model =
    insertTodo (Todo.init model.now form.text) model
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
                    updateTodo
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

                    ETFM_EditTodoSchedule ->
                        positionPopup "#edit-schedule-button-"
                )


onStartAddingTodo config addFormMode =
    let
        createXMode model =
            Todo.Form.createAddTodoForm addFormMode |> XMTodoForm
    in
        X.Return.returnWith createXMode config.setXMode
            >> autoFocusInputRCmd


onStopRunningTodo =
    mapSet timeTracker Tracker.none


onGotoRunningTodo : Config a msg model -> SubReturnF msg model
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


gotoRunningTodo : Config a msg model -> SubModel model -> SubReturnF msg model
gotoRunningTodo config model =
    Tracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithId config model
        ?= identity


gotoTodoWithId : Config a msg model -> SubModel model -> DocId -> SubReturnF msg model
gotoTodoWithId config model todoId =
    let
        maybeTodoEntity =
            Lazy.force config.currentViewEntityList
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
                    setFocusInEntityWithTodoId config todoId
                        >> config.switchToContextsView
                )
                config.setFocusInEntity


setFocusInEntityWithTodoId config =
    createTodoEntityId >> config.setFocusInEntityWithEntityId


positionMoreMenuCmd todoId =
    DomPorts.positionPopupMenu ("#todo-more-menu-button-" ++ todoId)


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


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
                andThen (updateTodo (TA_TurnReminderOff) todoId)
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
