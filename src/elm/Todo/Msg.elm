module Todo.Msg exposing (..)

import Document.Types exposing (DocId)
import Notification exposing (Response)
import Todo.Notification.Model
import Todo.Types exposing (TodoAction, TodoDoc)


type TodoMsg
    = ToggleRunning DocId
    | SwitchOrStartRunning DocId
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId DocId
    | GotoRunning
    | UpdateTimeTracker
    | Upsert TodoDoc
    | OnShowMoreMenu DocId
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode DocId TodoAction
    | OnReminderOverlayAction Todo.Notification.Model.Action
