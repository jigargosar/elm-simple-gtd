port module Update.CustomSync exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMEditSyncSettings, XMMainMenu))
import Msg exposing (..)
import Return exposing (command)
import ReturnTypes exposing (ReturnF)
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
