module ExclusiveMode.Types exposing (..)

import GroupDoc exposing (..)
import Menu.Types exposing (MenuState)
import Todo.FormTypes exposing (..)


type ExclusiveMode
    = XMTodoForm TodoForm
    | XMGroupDocForm GroupDocForm
    | XMMainMenu MenuState
    | XMSignInOverlay
    | XMNone
