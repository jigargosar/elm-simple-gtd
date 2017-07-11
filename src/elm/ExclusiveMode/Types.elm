module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Models exposing (LaunchBar)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (AddTodoForm, TodoEditForm, EditTodoReminderForm, TodoGroupFrom, TodoMoreMenuForm)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo AddTodoForm
    | XMEditTodo TodoEditForm
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMTodoMoreMenu TodoMoreMenuForm
    | XMEditTodoReminder EditTodoReminderForm
    | XMEditTodoContext TodoGroupFrom
    | XMEditTodoProject TodoGroupFrom
    | XMLaunchBar LaunchBar
    | XMLaunchBar2
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup AddTodoForm
    | XMNone
