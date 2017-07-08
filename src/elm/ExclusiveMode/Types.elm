module ExclusiveMode.Types exposing (..)

import LaunchBar.Form


-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Types exposing (LaunchBarForm)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (AddTodoForm, TodoEditForm, TodoEditReminderForm, TodoGroupFrom, TodoMoreMenuForm)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo AddTodoForm
    | XMEditTodo TodoEditForm
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMTodoMoreMenu TodoMoreMenuForm
    | XMEditTodoReminder TodoEditReminderForm
    | XMEditTodoContext TodoGroupFrom
    | XMEditTodoProject TodoGroupFrom
    | XMLaunchBar LaunchBarForm
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMSetup AddTodoForm
    | XMNone
