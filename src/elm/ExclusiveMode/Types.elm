module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocForm)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMEditContext GroupDocForm
    | XMEditProject GroupDocForm
      -- todo: merge above into EntityExclusiveMode. we will need to add new project and new context mode.
    | XMLaunchBar
    | XMMainMenu MenuState
    | XMEditSyncSettings SyncForm
    | XMSignInOverlay
    | XMNone
