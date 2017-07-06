module Todo.Msg exposing (..)

import Notification exposing (Response)
import Todo
import Todo.NewForm
import Todo.ReminderForm


type Msg
    = ToggleRunning Todo.Id
    | InitRunning Todo.Id
    | SwitchOrStartRunning Todo.Id
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId Todo.Id
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTodoText Todo.NewForm.Model String
    | Upsert Todo.Model
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu Todo.Id
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode Todo.Id Todo.UpdateAction
