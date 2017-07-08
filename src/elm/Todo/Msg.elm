module Todo.Msg exposing (..)

import Notification exposing (Response)
import Todo
import Todo.NewForm
import Todo.ReminderForm
import Types


type Msg
    = ToggleRunning Types.DocId
    | SwitchOrStartRunning Types.DocId
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId Types.DocId
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTodoText Todo.NewForm.Model String
    | Upsert Todo.Model
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu Types.DocId
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode Types.DocId Todo.UpdateAction
