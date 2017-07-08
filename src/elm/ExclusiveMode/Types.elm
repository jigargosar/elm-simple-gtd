module ExclusiveMode.Types exposing (..)

import ExclusiveMode exposing (SyncForm)
import GroupDoc.EditForm
import LaunchBar.Form
import Menu
import Todo.Form
import Todo.GroupForm
import Todo.Menu
import Todo.NewForm
import Todo.ReminderForm


type ExclusiveMode
    = NewTodo Todo.NewForm.Model
    | EditTodo Todo.Form.Model
    | EditContext GroupDoc.EditForm.Model
    | EditProject GroupDoc.EditForm.Model
      -- overlay
    | TodoMoreMenu Todo.Menu.Model
    | EditTodoReminder Todo.ReminderForm.Model
    | EditTodoContext Todo.GroupForm.Model
    | EditTodoProject Todo.GroupForm.Model
    | LaunchBar LaunchBar.Form.Model
    | MainMenu Menu.State
      -- different page !!
    | EditSyncSettings SyncForm
    | SignInOverlay
    | Setup Todo.NewForm.Model
    | None
