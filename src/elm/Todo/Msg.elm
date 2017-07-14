module Todo.Msg exposing (..)

import Document.Types exposing (DocId)
import Notification exposing (Response)
import Todo.FormTypes exposing (AddTodoFormMode, EditTodoFormMode, TodoForm, TodoFormAction)
import Todo.Notification.Model
import Todo.Types exposing (TodoAction, TodoDoc)


type TodoMsg
    = ToggleRunning DocId
    | SwitchOrStartRunning DocId
    | OnStopRunningTodo
    | RunningNotificationResponse Response
    | OnReminderNotificationClicked Notification.TodoNotificationEvent
    | ShowReminderOverlayForTodoId DocId
    | OnGotoRunningTodo
    | UpdateTimeTracker
    | Upsert TodoDoc
    | OnProcessPendingNotificationCronTick
    | OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode DocId TodoAction
    | OnTodoReminderOverlayAction Todo.Notification.Model.Action
    | OnStartAddingTodo AddTodoFormMode
    | OnStartEditingTodo TodoDoc EditTodoFormMode
    | OnUpdateTodoForm TodoForm TodoFormAction
