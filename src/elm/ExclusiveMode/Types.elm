module ExclusiveMode.Types exposing (..)

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Form
import Menu
import Todo.Form
import Todo.GroupForm
import Todo.Menu
import Todo.NewForm
import Todo.ReminderForm


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo Todo.NewForm.Model
    | XMEditTodo Todo.Form.Model
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMTodoMoreMenu Todo.Menu.Model
    | XMEditTodoReminder Todo.ReminderForm.Model
    | XMEditTodoContext Todo.GroupForm.Model
    | XMEditTodoProject Todo.GroupForm.Model
    | XMLaunchBar LaunchBar.Form.Model
    | XMMainMenu Menu.State
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup Todo.NewForm.Model
    | XMNone
