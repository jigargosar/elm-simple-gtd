module Todo.Msg exposing (..)

import Notification exposing (Response)
import Todo
import Todo.NewForm
import Todo.ReminderForm
import Types


type Msg
    = ToggleRunning Types.DocId__
    | SwitchOrStartRunning Types.DocId__
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId Types.DocId__
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTodoText Todo.NewForm.Model String
    | Upsert Todo.Model
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu Types.DocId__
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode Types.DocId__ Todo.UpdateAction
