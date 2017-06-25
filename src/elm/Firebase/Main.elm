port module Firebase.Main exposing (..)

import AppUrl
import Firebase
import Firebase.SignIn
import Model
import Navigation
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time
import X.Record
import X.Return


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
                >> Return.map (overSignInModel Firebase.SignIn.updateOnTriedSignIn)
                >> andThenUpdate Model.OnPersistLocalPref

        Firebase.OnSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.updateOnTriedSignOut)
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
                                andThenUpdate Model.OnDeactivateEditingMode
                )
                >> X.Return.mapModelWith (.user)
                    (\user -> overSignInModel (Firebase.SignIn.updateAfterUserChanged user))
