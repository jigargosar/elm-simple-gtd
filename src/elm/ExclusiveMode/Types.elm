module ExclusiveMode.Types exposing (..)

import LaunchBar.Form


-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (TodoEditForm, TodoGroupFrom)
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
    | XMEditTodoContext TodoGroupFrom
    | XMEditTodoProject TodoGroupFrom
    | XMLaunchBar LaunchBar.Form.Model
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup Todo.NewForm.Model
    | XMNone
