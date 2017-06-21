module Todo.Msg exposing (..)

import Menu
import Notification exposing (Response)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
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
    | GotoRunning
    | UpdateTimeTracker
    | Upsert Todo.Model
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnShowMoreMenu Todo.Id
