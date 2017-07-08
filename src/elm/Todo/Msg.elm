module Todo.Msg exposing (..)

import Document.Types exposing (DocId)
import Notification exposing (Response)
import Todo
import Todo.NewForm
import Todo.ReminderForm
import Todo.Types exposing (TodoDoc)


type Msg
    = ToggleRunning DocId
    | SwitchOrStartRunning DocId
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId DocId
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTodoText Todo.NewForm.Model String
    | Upsert TodoDoc
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu DocId
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode DocId Todo.UpdateAction
