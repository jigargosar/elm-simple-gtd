module Todo.Msg exposing (..)

import Document.Types exposing (DocId)
import Notification exposing (Response)
import Todo
import Todo.FormTypes exposing (AddTodoForm, TodoEditReminderForm)
import Todo.NewForm
import Todo.ReminderForm
import Todo.Types exposing (TodoAction, TodoDoc)


type Msg
    = ToggleRunning DocId
    | SwitchOrStartRunning DocId
    | StopRunning
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId DocId
    | GotoRunning
    | UpdateTimeTracker
    | UpdateSetupFormTodoText AddTodoForm String
    | Upsert TodoDoc
    | UpdateReminderForm TodoEditReminderForm Todo.ReminderForm.Action
    | OnShowMoreMenu DocId
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode DocId TodoAction
