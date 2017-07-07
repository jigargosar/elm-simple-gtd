port module Firebase.Main exposing (..)

import AppUrl
import Firebase exposing (Msg(..))
import Firebase.Model exposing (User(..))
import Firebase.SignIn
import Model
import Navigation
import Return
import Time
import X.Record exposing (over, set)
import X.Return exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Msg


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( Firebase.UID, Firebase.DeviceId ) -> Cmd msg


port onFirebaseUserChanged : (E.Value -> msg) -> Sub msg


port onFCMTokenChanged : (E.Value -> msg) -> Sub msg


port onFirebaseConnectionChanged : (Bool -> msg) -> Sub msg


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


subscriptions : Model.Subscriptions
subscriptions model =
    Sub.batch
        [ onFirebaseUserChanged OnUserChanged
        , onFCMTokenChanged OnFCMTokenChanged
        , onFirebaseConnectionChanged OnFirebaseConnectionChanged
        ]
        |> Sub.map Msg.OnFirebaseMsg


overSignInModel =
    X.Record.over Model.signInModel


update :
    (Msg.Msg -> Model.ReturnF)
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
                >> andThenUpdate Msg.OnPersistLocalPref
                >> Return.map (Model.switchToNewUserSetupModeIfNeeded)

        OnSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
                >> andThenUpdate Msg.OnPersistLocalPref
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
                                    >> andThenUpdate Msg.OnPersistLocalPref
                                    >> Return.map (Model.switchToNewUserSetupModeIfNeeded)
                )

        OnUserChanged encodedUser ->
            D.decodeValue Firebase.Model.userDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\user ->
                        Return.map (setUser user)
                            >> andThenUpdate (Msg.OnFirebaseMsg AfterUserChanged)
                            >> maybeEffect firebaseUpdateClientCmd
                            >> maybeEffect firebaseSetupOnDisconnectCmd
                            >> startSyncWithFirebase
                    )
                != identity

        OnFCMTokenChanged encodedToken ->
            D.decodeValue Firebase.Model.fcmTokenDecoder encodedToken
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\token ->
                        Return.map (setFCMToken token)
                            >> maybeEffect firebaseUpdateClientCmd
                    )
                != identity

        OnFirebaseConnectionChanged connected ->
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
    X.Record.field .firebaseClient (\s b -> { b | firebaseClient = s })


user =
    X.Record.field .user (\s b -> { b | user = s })
