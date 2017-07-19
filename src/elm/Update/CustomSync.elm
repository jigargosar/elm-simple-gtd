port module Update.CustomSync exposing (Config, update)

import ExclusiveMode.Types exposing (..)
import Msg.CustomSync exposing (CustomSyncMsg(..))
import Return exposing (command)


port syncWithRemotePouch : String -> Cmd msg


type alias SubModel model =
    { model | pouchDBRemoteSyncURI : String }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config a msg model =
    { a
        | saveXModeForm : SubReturnF msg model
        , setXMode : ExclusiveMode -> SubReturnF msg model
    }


update :
    Config a msg model
    -> CustomSyncMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnStartCustomSync form ->
            config.saveXModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnUpdateCustomSyncFormUri form uri ->
            { form | uri = uri }
                |> XMCustomSync
                >> config.setXMode
