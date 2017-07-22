module Update.Firebase exposing (Config, update)

import AppUrl
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase
import Firebase.Model
import Firebase.SignIn
import Firebase.Types exposing (..)
import Json.Decode as D exposing (Decoder)
import Navigation
import Ports.Firebase exposing (..)
import Return exposing (command)
import Store
import Todo.Types exposing (TodoStore)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (over, set)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | user : FirebaseUser
        , fcmToken : FCMToken
        , firebaseClient : FirebaseClient
        , signInModel : Firebase.SignIn.Model
        , todoStore : TodoStore
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg model =
    { onStartSetupAddTodo : SubReturnF msg model
    , revertExclusiveMode : SubReturnF msg model
    , onSetExclusiveMode : ExclusiveMode -> SubReturnF msg model
    , onSwitchToNewUserSetupModeIfNeeded : SubReturnF msg model
    }


update :
    Config msg model
    -> FirebaseMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnFB_NOOP ->
            identity

        OnFB_SwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded model =
                    if Firebase.SignIn.shouldSkipSignIn model.signInModel then
                        if Store.isEmpty model.todoStore then
                            config.onStartSetupAddTodo
                        else
                            config.revertExclusiveMode
                    else
                        config.onSetExclusiveMode XMSignInOverlay
            in
            returnWith identity onSwitchToNewUserSetupModeIfNeeded

        OnFBSignIn ->
            command (signIn ())

        OnFBSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> config.onSwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
                >> command (Navigation.load AppUrl.landing)

        OnFBAfterUserChanged ->
            Return.andThen
                (\model ->
                    Return.singleton model
                        |> (case model.user of
                                SignedOut ->
                                    identity

                                SignedIn user ->
                                    Return.map
                                        (overSignInModel Firebase.SignIn.setStateToSignInSuccess)
                                        >> config.onSwitchToNewUserSetupModeIfNeeded
                           )
                )

        OnFBUserChanged encodedUser ->
            D.decodeValue Firebase.Model.userDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\user ->
                        Return.map (setUser user)
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
            Return.map (updateFirebaseConnection connected)
                >> maybeEffect firebaseUpdateClientCmd


signInModel =
    X.Record.fieldLens .signInModel (\s b -> { b | signInModel = s })


firebaseClient =
    X.Record.fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


user =
    X.Record.fieldLens .user (\s b -> { b | user = s })


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


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )
