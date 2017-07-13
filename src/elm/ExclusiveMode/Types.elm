module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocEditForm)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMTodo TodoExclusiveMode
    | XMEditContext GroupDocEditForm
    | XMEditProject GroupDocEditForm
    | XMLaunchBar
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMNone
