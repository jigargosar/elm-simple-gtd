module Update.AppHeader exposing (..)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMMainMenu))
import Menu
import Msg exposing (..)
import Return exposing (command)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (ReturnF)
import XMMsg


update :
    (AppMsg -> ReturnF)
    -> AppHeaderMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnShowMainMenu ->
            andThenUpdate (XMMsg.onSetExclusiveMode (XMMainMenu Menu.initState))
                >> command positionMainMenuCmd

        OnMainMenuStateChanged menuState ->
            (menuState
                |> XMMainMenu
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate
            )
                >> DomPorts.autoFocusInputRCmd


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"
