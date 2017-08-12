module Overlays.MainMenu exposing (..)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMMainMenu))
import List.Extra as List
import Maybe.Extra as Maybe
import Menu
import Menu.Types exposing (MenuState)
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Return exposing (..)


type MainMenuMsg
    = OnShowMainMenu
    | OnMainMenuStateChanged MenuState


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
    -> MainMenuMsg
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
