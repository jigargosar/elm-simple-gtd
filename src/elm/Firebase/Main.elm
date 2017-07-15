port module Firebase.Main exposing (..)

import AppUrl
import Firebase
import Firebase.Model
import Firebase.SignIn
import Firebase.Types exposing (..)
import Navigation
import Return
import X.Record exposing (over, set)
import X.Return exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Msg
import Types exposing (ReturnF, Subscriptions)


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( Firebase.UID, Firebase.Types.DeviceId ) -> Cmd msg


port onFirebaseUserChanged : (E.Value -> msg) -> Sub msg


port onFCMTokenChanged : (E.Value -> msg) -> Sub msg


port onFirebaseConnectionChanged : (Bool -> msg) -> Sub msg


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


subscriptions : Subscriptions
subscriptions model =
    Sub.batch
        [ onFirebaseUserChanged OnFBUserChanged
        , onFCMTokenChanged OnFBFCMTokenChanged
        , onFirebaseConnectionChanged OnFBConnectionChanged
        ]
        |> Sub.map Msg.OnFirebaseMsg


signInModel =
    X.Record.fieldLens .signInModel (\s b -> { b | signInModel = s })


overSignInModel =
    X.Record.over signInModel


update :
    (Msg.AppMsg -> ReturnF)
    -> FirebaseMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnFBNOOP ->
            identity

        OnFBSignIn ->
            Return.command (signIn ())

        OnFBSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> andThenUpdate Msg.OnPersistLocalPref
                >> andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
                >> andThenUpdate Msg.OnPersistLocalPref
                >> Return.command (Navigation.load AppUrl.landing)

        OnFBAfterUserChanged ->
            Return.andThen
                (\model ->
                    Return.singleton model
                        |> case model.user of
                            SignedOut ->
                                identity

                            SignedIn user ->
                                Return.map
                                    (overSignInModel Firebase.SignIn.setStateToSignInSuccess)
                                    >> andThenUpdate Msg.OnPersistLocalPref
                                    >> andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded
                )

        OnFBUserChanged encodedUser ->
            D.decodeValue Firebase.Model.userDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\user ->
                        Return.map (setUser user)
                            >> andThenUpdate (Msg.OnFirebaseMsg OnFBAfterUserChanged)
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
            Return.map (updateFirebaseConnection connected)
                >> maybeEffect firebaseUpdateClientCmd


firebaseUpdateClientCmd model =
    getMaybeUserId model
        ?|> updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseClient


startSyncWithFirebase =
    maybeEffect (getMaybeUserId >>? startSyncCmd)


setFCMToken fcmToken model =
    { model | fcmToken = fcmToken }
        |> over firebaseClient (Firebase.updateToken fcmToken)


updateFirebaseConnection connected =
    over firebaseClient (Firebase.updateConnection connected)


getMaybeUserId =
    .user >> Firebase.Model.getMaybeUserId


setUser =
    set user


firebaseClient =
    X.Record.fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


user =
    X.Record.fieldLens .user (\s b -> { b | user = s })
