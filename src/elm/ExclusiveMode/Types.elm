module ExclusiveMode.Types exposing (..)

-- small so safe

import LaunchBar.Models
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)
import Types.GroupDoc exposing (..)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMGroupDocForm GroupDocForm
    | XMLaunchBar LaunchBar.Models.LaunchBarForm
    | XMMainMenu MenuState
    | XMSignInOverlay
    | XMCustomSync SyncForm
    | XMNone
