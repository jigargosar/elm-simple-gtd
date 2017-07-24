module Update.AppHeader exposing (Config, update)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMMainMenu))
import Menu
import Msg.AppHeader exposing (AppHeaderMsg(..))
import Return
import X.Return exposing (..)


type alias SubModel model =
    model


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg model =
    { setXMode : ExclusiveMode -> SubReturnF msg model
    }


update :
    Config msg model
    -> AppHeaderMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnShowMainMenu ->
            config.setXMode (XMMainMenu Menu.initState)
                >> command positionMainMenuCmd

        OnMainMenuStateChanged menuState ->
            menuState
                |> XMMainMenu
                >> config.setXMode


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"
