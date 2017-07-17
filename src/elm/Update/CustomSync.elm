port module Update.CustomSync exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMEditSyncSettings, XMMainMenu))
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Return exposing (command)
import Types exposing (AppModel)


port syncWithRemotePouch : String -> Cmd msg


type alias SubReturnF msg =
    Return.ReturnF msg AppModel


type alias Config msg =
    { saveXModeForm : SubReturnF msg
    , setXMode : ExclusiveMode -> SubReturnF msg
    }


update :
    Config msg
    -> CustomSyncMsg
    -> SubReturnF msg
update config msg =
    case msg of
        OnStartCustomSync form ->
            config.saveXModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateCustomSyncFormUri form uri ->
            { form | uri = uri }
                |> XMEditSyncSettings
                >> config.setXMode
