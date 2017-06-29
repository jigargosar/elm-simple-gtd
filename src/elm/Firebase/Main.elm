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


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


overSignInModel =
    X.Record.over Model.signInModel


update :
    (Model.Msg -> Model.ReturnF)
    -> Time.Time
    -> Firebase.Msg
    -> Model.ReturnF
update andThenUpdate now msg =
    case msg of
        NOOP ->
            identity

        OnSignIn ->
            Return.command (signIn ())

        OnSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> andThenUpdate Model.OnPersistLocalPref
                >> andThenUpdate Model.OnSwitchToNewUserSetupModeIfNeeded

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
                                    >> andThenUpdate Model.OnSwitchToNewUserSetupModeIfNeeded
                )

        OnUserChanged user ->
            Return.map (Model.setUser user)
                >> andThenUpdate (Model.OnFirebaseMsg AfterUserChanged)
                >> maybeEffect firebaseUpdateClientCmd
                >> maybeEffect firebaseSetupOnDisconnectCmd
                >> startSyncWithFirebase user

        OnFCMTokenChanged token ->
            Return.map (Model.setFCMToken token)
                >> maybeEffect firebaseUpdateClientCmd

        OnFirebaseConnectionChanged connected ->
            Return.map (Model.updateFirebaseConnection connected)
                >> maybeEffect firebaseUpdateClientCmd


firebaseUpdateClientCmd model =
    Model.getMaybeUserId model
        ?|> Firebase.updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    Model.getMaybeUserId model
        ?|> Firebase.setupOnDisconnectCmd model.firebaseClient


startSyncWithFirebase user =
    maybeEffect (Model.getMaybeUserId >>? Firebase.startSyncCmd)
