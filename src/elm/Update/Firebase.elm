module Update.Firebase exposing (Config, update)

import AppUrl
import Data.User
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase.Model exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Maybe.Extra
import Msg.Firebase exposing (..)
import Navigation
import Ports
import Ports.Firebase exposing (..)
import Return
import Store
import Toolkit.Operators exposing (..)
import Types.Todo exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubReturnF msg =
    Return.ReturnF msg FirebaseModel


type alias Config msg a =
    { a
        | onStartSetupAddTodo : msg
        , revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , isTodoStoreEmpty : Bool
    }


update :
    Config msg a
    -> FirebaseMsg
    -> SubReturnF msg
update config msg =
    case msg of
        OnFB_NOOP ->
            identity

        OnFB_SwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded model =
                    if model.showSignInDialog then
                        config.onSetExclusiveMode XMSignInOverlay |> returnMsgAsCmd
                    else if config.isTodoStoreEmpty then
                        returnMsgAsCmd config.onStartSetupAddTodo
                    else
                        returnMsgAsCmd config.revertExclusiveMode
            in
            returnWith identity onSwitchToNewUserSetupModeIfNeeded

        OnFBSignIn ->
            command (signIn ())
                >> setAndPersistShowSignInDialogValue True
                >> update config OnFB_SwitchToNewUserSetupModeIfNeeded

        OnFBSkipSignIn ->
            setAndPersistShowSignInDialogValue False
                >> update config OnFB_SwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            Return.command (signOut ())
                >> setAndPersistShowSignInDialogValue True
                >> command (Navigation.load AppUrl.landing)

        OnFBAfterUserChanged ->
            returnWithMaybe1 .maybeUser
                (\_ ->
                    setAndPersistShowSignInDialogValue False
                        >> update config OnFB_SwitchToNewUserSetupModeIfNeeded
                )

        OnFBUserChanged encodedUser ->
            D.decodeValue Data.User.maybeUserDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\userV ->
                        Return.map (set userL userV)
                            >> update config OnFBAfterUserChanged
                            >> maybeEffect firebaseUpdateClientCmd
                            >> maybeEffect firebaseSetupOnDisconnectCmd
                            >> startSyncWithFirebase
                    )
                != identity

        OnFBFCMTokenChanged encodedToken ->
            D.decodeValue Firebase.Model.fcmTokenDecoder encodedToken
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\token ->
                        Return.map (setFCMToken token)
                            >> maybeEffect firebaseUpdateClientCmd
                    )
                != identity

        OnFBConnectionChanged connected ->
            Return.map (setClientConnectionStatus connected)
                >> maybeEffect firebaseUpdateClientCmd


showSignInDialog =
    fieldLens .showSignInDialog (\s b -> { b | showSignInDialog = s })


signInModelL =
    fieldLens .signInModel (\s b -> { b | signInModel = s })


firebaseClientL =
    fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


userL =
    fieldLens .maybeUser (\s b -> { b | maybeUser = s })


fcmTokenL =
    fieldLens .fcmToken (\s b -> { b | fcmToken = s })


setAndPersistShowSignInDialogValue bool =
    map (set showSignInDialog bool)
        >> command (Ports.persistToOfflineStore ( "showSignInDialog", E.bool bool ))


firebaseUpdateClientCmd model =
    getMaybeUserId model
        ?|> updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseClient


startSyncWithFirebase =
    maybeEffect (getMaybeUserId >>? startSyncCmd)


setFCMToken fcmToken =
    set fcmTokenL fcmToken
        >> over firebaseClientL (\client -> { client | token = fcmToken })


setClientConnectionStatus =
    setClientConnectedStatus >> over firebaseClientL


getMaybeUserId =
    .maybeUser >> Firebase.Model.getMaybeUserId


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


setClientConnectedStatus connected client =
    { client | connected = connected }
