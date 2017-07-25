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


type alias Config msg a =
    { a
        | onSetExclusiveMode : ExclusiveMode -> msg
    }


update :
    Config msg a
    -> AppHeaderMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnShowMainMenu ->
            (config.onSetExclusiveMode (XMMainMenu Menu.initState)
                |> returnMsgAsCmd
            )
                >> command positionMainMenuCmd

        OnMainMenuStateChanged menuState ->
            menuState
                |> XMMainMenu
                >> config.onSetExclusiveMode
                >> returnMsgAsCmd


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"
