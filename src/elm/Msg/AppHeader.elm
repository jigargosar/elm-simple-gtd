module Msg.AppHeader exposing (..)

import Menu.Types exposing (MenuState)


type AppHeaderMsg
    = OnShowMainMenu
    | OnMainMenuStateChanged MenuState
