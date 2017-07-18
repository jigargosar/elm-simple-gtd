module ExclusiveMode.Types exposing (..)

-- small so safe

import GroupDoc.FormTypes exposing (GroupDocForm)
import LaunchBar.Models
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMGroupDocForm GroupDocForm
    | XMLaunchBar LaunchBar.Models.LaunchBar
    | XMMainMenu MenuState
    | XMSignInOverlay
    | XMCustomSync SyncForm
    | XMNone
