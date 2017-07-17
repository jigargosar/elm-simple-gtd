port module Update.CustomSync exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMEditSyncSettings, XMMainMenu))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Return exposing (command)


port syncWithRemotePouch : String -> Cmd msg



{-
   update :
       (AppMsg -> ReturnF)
       -> CustomSyncMsg
       -> ReturnF
-}


update config msg =
    case msg of
        OnStartCustomSync form ->
            config.saveXModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateCustomSyncFormUri form uri ->
            { form | uri = uri }
                |> XMEditSyncSettings
                >> config.setXMode
