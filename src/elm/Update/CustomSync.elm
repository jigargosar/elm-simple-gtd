port module Update.CustomSync exposing (..)

import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMEditSyncSettings, XMMainMenu))
import Menu
import Msg exposing (..)
import Return exposing (command)
import ReturnTypes exposing (ReturnF)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import XMMsg


port syncWithRemotePouch : String -> Cmd msg


update :
    (AppMsg -> ReturnF)
    -> CustomSyncMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnStartCustomSync form ->
            andThenUpdate XMMsg.onSaveExclusiveModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateCustomSyncFormUri form uri ->
            { form | uri = uri }
                |> XMEditSyncSettings
                >> XMMsg.onSetExclusiveMode
                >> andThenUpdate
