module ExclusiveMode.Types exposing (..)

import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)
import Types.GroupDoc exposing (..)


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMGroupDocForm GroupDocForm
    | XMMainMenu MenuState
    | XMSignInOverlay
    | XMNone
