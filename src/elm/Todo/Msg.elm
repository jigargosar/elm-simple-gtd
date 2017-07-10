module Todo.Msg exposing (..)

import Document.Types exposing (DocId)
import Notification exposing (Response)
import Todo.FormTypes exposing (AddTodoForm, EditTodoReminderFormAction, EditTodoReminderForm)
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
    | UpdateSetupFormTodoText AddTodoForm String
    | Upsert TodoDoc
    | UpdateReminderForm EditTodoReminderForm EditTodoReminderFormAction
    | OnShowMoreMenu DocId
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode DocId TodoAction
    | OnNewTodoForInbox
