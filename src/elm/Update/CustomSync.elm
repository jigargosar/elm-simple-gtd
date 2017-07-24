port module Update.CustomSync exposing (Config, update)

import ExclusiveMode.Types exposing (..)
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Return
import X.Return exposing (..)


port syncWithRemotePouch : String -> Cmd msg


type alias SubModel model =
    { model | pouchDBRemoteSyncURI : String }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg =
    { saveXModeForm : msg
    , setXMode : ExclusiveMode -> msg
    }


update :
    Config msg
    -> CustomSyncMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnStartCustomSync form ->
            returnMsgAsCmd config.saveXModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateCustomSyncFormUri form uri ->
            { form | uri = uri }
                |> XMCustomSync
                >> config.setXMode
                >> returnMsgAsCmd
