port module Firebase.Main exposing (..)

import AppUrl
import Firebase exposing (Msg(..), User(..))
import Firebase.SignIn
import Model
import Navigation
import Return
import Time
import X.Record
import X.Return exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( Firebase.UID, Firebase.DeviceId ) -> Cmd msg


port onFirebaseUserChanged : (E.Value -> msg) -> Sub msg


port onFCMTokenChanged : (E.Value -> msg) -> Sub msg


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.encodeClient client )


subscriptions : Model.Subscriptions
subscriptions model =
    Sub.batch
        [ onFirebaseUserChanged OnUserChanged
        ]
        |> Sub.map Model.OnFirebaseMsg


overSignInModel =
    X.Record.over Model.signInModel


update :
    (Model.Msg -> Model.ReturnF)
    -> Firebase.Msg
    -> Model.ReturnF
update andThenUpdate msg =
    case msg of
        NOOP ->
            identity

        OnSignIn ->
            Return.command (signIn ())

        OnSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> andThenUpdate Model.OnPersistLocalPref
                >> Return.map (Model.switchToNewUserSetupModeIfNeeded)

        OnSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
                >> andThenUpdate Model.OnPersistLocalPref
                >> Return.command (Navigation.load AppUrl.landing)

        AfterUserChanged ->
            Return.andThen
                (\model ->
                    Return.singleton model
                        |> case model.user of
                            SignedOut ->
                                identity

                            SignedIn user ->
                                Return.map
                                    (overSignInModel Firebase.SignIn.setStateToSignInSuccess)
                                    >> andThenUpdate Model.OnPersistLocalPref
                                    >> Return.map (Model.switchToNewUserSetupModeIfNeeded)
                )

        OnUserChanged encodedUser ->
            D.decodeValue Firebase.userDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\user ->
                        Return.map (Model.setUser user)
                            >> andThenUpdate (Model.OnFirebaseMsg AfterUserChanged)
                            >> maybeEffect firebaseUpdateClientCmd
                            >> maybeEffect firebaseSetupOnDisconnectCmd
                            >> startSyncWithFirebase user
                    )
                != identity

        OnFCMTokenChanged encodedToken ->
            D.decodeValue Firebase.fcmTokenDecoder encodedToken
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\token ->
                        Return.map (Model.setFCMToken token)
                            >> maybeEffect firebaseUpdateClientCmd
                    )
                != identity

        OnFirebaseConnectionChanged connected ->
            Return.map (Model.updateFirebaseConnection connected)
                >> maybeEffect firebaseUpdateClientCmd


firebaseUpdateClientCmd model =
    Model.getMaybeUserId model
        ?|> updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    Model.getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseClient


startSyncWithFirebase user =
    maybeEffect (Model.getMaybeUserId >>? startSyncCmd)
