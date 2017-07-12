module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Models exposing (LaunchBar)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (AddTodoForm, EditTodoForm, EditTodoReminderForm, EditTodoForm, TodoMoreMenuForm)
import Todo.Types exposing (TodoDoc)


type alias SyncForm =
    { uri : String }


type XMEditTodoType
    = XMEditTodoText
    | XMEditTodoReminder
    | XMEditTodoContext
    | XMEditTodoProject


type ExclusiveMode
    = XMNewTodo AddTodoForm
    | XMSetup AddTodoForm
    | XMTodoMoreMenu TodoMoreMenuForm
    | XMEditTodo EditTodoForm XMEditTodoType
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMLaunchBar
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMNone
