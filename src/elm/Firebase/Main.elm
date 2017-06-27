port module Firebase.Main exposing (..)

import AppUrl
import Firebase
import Firebase.SignIn
import Model
import Navigation
import Return
import Time
import X.Record


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
        Firebase.OnSignIn ->
            Return.command (signIn ())

        Firebase.OnSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> andThenUpdate Model.OnPersistLocalPref
                >> andThenUpdate Model.OnSwitchToNewUserSetupModeIfNeeded

        Firebase.OnSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
                >> andThenUpdate Model.OnPersistLocalPref
                >> Return.command (Navigation.load AppUrl.landing)

        Firebase.AfterUserChanged ->
            Return.andThen
                (\model ->
                    Return.singleton model
                        |> case model.user of
                            Firebase.SignedOut ->
                                identity

                            Firebase.SignedIn user ->
                                Return.map
                                    (overSignInModel Firebase.SignIn.setStateToSignInSuccess)
                                    >> andThenUpdate Model.OnPersistLocalPref
                                    >> andThenUpdate Model.OnSwitchToNewUserSetupModeIfNeeded
                )
