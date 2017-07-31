module ExclusiveMode.Types exposing (..)

import Menu.Types exposing (MenuState)
import Overlays.LaunchBar
import Todo.FormTypes exposing (..)
import Types.GroupDoc exposing (..)


type alias SyncForm =
    { uri : String }


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMGroupDocForm GroupDocForm
    | XMLaunchBar Overlays.LaunchBar.LaunchBarForm
    | XMMainMenu MenuState
    | XMSignInOverlay
    | XMCustomSync SyncForm
    | XMNone
