module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Types exposing (LaunchBarForm)
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
    | XMLaunchBar LaunchBarForm
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup AddTodoForm
    | XMNone
