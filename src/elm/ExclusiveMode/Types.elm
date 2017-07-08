module ExclusiveMode.Types exposing (..)

import LaunchBar.Form


-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import Menu.Types exposing (MenuState)
import Todo.Form
import Todo.FormTypes exposing (TodoEditForm)
import Todo.GroupForm
import Todo.Menu
import Todo.NewForm
import Todo.ReminderForm


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo Todo.NewForm.Model
    | XMEditTodo TodoEditForm
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMTodoMoreMenu Todo.Menu.Model
    | XMEditTodoReminder Todo.ReminderForm.Model
    | XMEditTodoContext Todo.GroupForm.Model
    | XMEditTodoProject Todo.GroupForm.Model
    | XMLaunchBar LaunchBar.Form.Model
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup Todo.NewForm.Model
    | XMNone
