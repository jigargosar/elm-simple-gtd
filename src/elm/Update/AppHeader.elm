module Update.AppHeader exposing (..)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMMainMenu))
import Menu
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Return exposing (command)
import Types exposing (AppModel)
import Update.Types exposing (SubReturnF)


type alias Config msg =
    { setXMode : ExclusiveMode -> SubReturnF msg
    }


update :
    Config msg
    -> AppHeaderMsg
    -> SubReturnF msg
update config msg =
    case msg of
        OnShowMainMenu ->
            config.setXMode (XMMainMenu Menu.initState)
                >> command positionMainMenuCmd

        OnMainMenuStateChanged menuState ->
            (menuState
                |> XMMainMenu
                >> config.setXMode
            )
                >> DomPorts.autoFocusInputRCmd


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"
