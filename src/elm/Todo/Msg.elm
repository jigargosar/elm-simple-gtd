module Todo.Msg exposing (..)

import Menu
import Notification exposing (Response)
import Todo
import Todo.NewForm
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo.ReminderForm


type Msg
    = ToggleRunning Todo.Id
    | InitRunning Todo.Id
    | SwitchOrStartRunning Todo.Id
    | StopRunning
    | TogglePaused
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId Todo.Id
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTaskText Todo.NewForm.Model String
    | Upsert Todo.Model
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu Todo.Id
    | OnProcessPendingNotificationCronTick
