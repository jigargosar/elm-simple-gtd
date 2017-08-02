module Update.Firebase exposing (Config, update)

import AppUrl
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase.Model
import Firebase.SignIn exposing (SignInModel, SignInModelF)
import Json.Decode as D exposing (Decoder)
import Msg.Firebase exposing (..)
import Navigation
import Ports.Firebase exposing (..)
import Return
import Store
import Toolkit.Operators exposing (..)
import Types.Firebase exposing (..)
import Types.Todo exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | firebaseModel : FirebaseModel
        , todoStore : TodoStore
    }


type alias SubModelF model =
    SubModel model -> SubModel model


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg a =
    { a
        | onStartSetupAddTodo : msg
        , revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
    }


update :
    Config msg a
    -> FirebaseMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnFB_NOOP ->
            identity

        OnFB_SwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded model =
                    if Firebase.SignIn.shouldSkipSignIn model.firebaseModel.signInModel then
                        if Store.isEmpty model.todoStore then
                            returnMsgAsCmd config.onStartSetupAddTodo
                        else
                            returnMsgAsCmd config.revertExclusiveMode
                    else
                        config.onSetExclusiveMode XMSignInOverlay |> returnMsgAsCmd
            in
            returnWith identity onSwitchToNewUserSetupModeIfNeeded

        OnFBSignIn ->
            command (signIn ())
                >> Return.map (overSignInModelInFirebaseModel Firebase.SignIn.setStateToTriedSignOut)
                >> update config OnFB_SwitchToNewUserSetupModeIfNeeded

        OnFBSkipSignIn ->
            Return.map (overSignInModelInFirebaseModel Firebase.SignIn.setSkipSignIn)
                >> update config OnFB_SwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModelInFirebaseModel Firebase.SignIn.setStateToTriedSignOut)
                >> command (Navigation.load AppUrl.landing)

        OnFBAfterUserChanged ->
            Return.andThen
                (\model ->
                    Return.singleton model
                        |> (case model.firebaseModel.user of
                                SignedOut ->
                                    identity

                                SignedIn user ->
                                    Return.map
                                        (overSignInModelInFirebaseModel
                                            Firebase.SignIn.setStateToSignInSuccess
                                        )
                                        >> update config OnFB_SwitchToNewUserSetupModeIfNeeded
                           )
                )

        OnFBUserChanged encodedUser ->
            D.decodeValue Firebase.Model.userDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\user ->
                        Return.map (setUserInFirebaseModel user)
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
                        Return.map (setFCMTokenInFirebaseModel token)
                            >> maybeEffect firebaseUpdateClientCmd
                    )
                != identity

        OnFBConnectionChanged connected ->
            Return.map (setClientConnectionStatusInFirebaseModel connected)
                >> maybeEffect firebaseUpdateClientCmd


signInModelL =
    fieldLens .signInModel (\s b -> { b | signInModel = s })


firebaseClientL =
    fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


userL =
    fieldLens .user (\s b -> { b | user = s })


fcmTokenL =
    fieldLens .fcmToken (\s b -> { b | fcmToken = s })


firebaseModelL : Field FirebaseModel (SubModel model)
firebaseModelL =
    fieldLens .firebaseModel (\s b -> { b | firebaseModel = s })


overSignInModelInFirebaseModel : SignInModelF -> SubModelF model
overSignInModelInFirebaseModel =
    over signInModelL >> over firebaseModelL


firebaseUpdateClientCmd model =
    getMaybeUserId model
        ?|> updateClientCmd model.firebaseModel.firebaseClient


firebaseSetupOnDisconnectCmd model =
    getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseModel.firebaseClient


startSyncWithFirebase =
    maybeEffect (getMaybeUserId >>? startSyncCmd)


setFCMTokenInFirebaseModel fcmToken =
    over firebaseModelL (set fcmTokenL fcmToken)
        >> overFirebaseClientInFirebaseModel (\client -> { client | token = fcmToken })


overFirebaseClientInFirebaseModel =
    over firebaseClientL >> over firebaseModelL


setClientConnectionStatusInFirebaseModel =
    setClientConnectedStatus >> overFirebaseClientInFirebaseModel


getMaybeUserId =
    .firebaseModel >> .user >> Firebase.Model.getMaybeUserId


setUserInFirebaseModel =
    set userL >> over firebaseModelL


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


setClientConnectedStatus connected client =
    { client | connected = connected }
