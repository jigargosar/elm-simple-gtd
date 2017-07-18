module Update.Firebase exposing (..)

import AppUrl
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase
import Firebase.Model
import Firebase.SignIn
import Firebase.Types exposing (..)
import Navigation
import Return
import Store
import TodoMsg
import Types exposing (..)
import X.Record exposing (over, set)
import X.Return exposing (..)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import Json.Decode as D exposing (Decoder)
import Msg exposing (AppMsg)
import Msg
import Ports.Firebase exposing (..)


type alias AppReturnF =
    Return.ReturnF AppMsg AppModel


update :
    (Msg.AppMsg -> AppReturnF)
    -> FirebaseMsg
    -> AppReturnF
update andThenUpdate msg =
    case msg of
        OnFB_NOOP ->
            identity

        OnFB_SwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded model =
                    Return.singleton model
                        |> if Firebase.SignIn.shouldSkipSignIn model.signInModel then
                            if Store.isEmpty model.todoStore then
                                andThenUpdate TodoMsg.onStartSetupAddTodo
                            else
                                andThenUpdate Msg.revertExclusiveMode
                           else
                            andThenUpdate (Msg.onSetExclusiveMode XMSignInOverlay)
            in
                Return.andThen onSwitchToNewUserSetupModeIfNeeded

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


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


signInModel =
    X.Record.fieldLens .signInModel (\s b -> { b | signInModel = s })


overSignInModel =
    X.Record.over signInModel


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
