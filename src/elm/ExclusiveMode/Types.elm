module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import LaunchBar.Models exposing (LaunchBar)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)
import Todo.Types exposing (TodoDoc)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMNewTodo AddTodoFormModel
    | XMSetup AddTodoFormModel
    | XMTodoMoreMenu TodoMoreMenuForm
    | XMTodo TodoForm
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMLaunchBar
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMNone
