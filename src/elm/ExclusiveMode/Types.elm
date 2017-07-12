module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Models exposing (LaunchBar)
import Menu.Types exposing (MenuState)
import Todo.Form exposing (AddTodoForm, TodoEditForm, EditTodoReminderForm, TodoEditForm, TodoMoreMenuForm)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo AddTodoForm
    | XMEditTodo
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMTodoMoreMenu TodoMoreMenuForm
    | XMEditTodoReminder EditTodoReminderForm
    | XMEditTodoContext
    | XMEditTodoProject
    | XMLaunchBar
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup AddTodoForm
    | XMNone
