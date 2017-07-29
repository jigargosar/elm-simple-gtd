module Update.Firebase exposing (Config, update)

import AppUrl
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase
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

        OnFBSkipSignIn ->
            Return.map (overSignInModel Firebase.SignIn.setSkipSignIn)
                >> update config OnFB_SwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            Return.command (signOut ())
                >> Return.map (overSignInModel Firebase.SignIn.setStateToTriedSignOut)
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
                                        (overSignInModel
                                            Firebase.SignIn.setStateToSignInSuccess
                                        )
                                        >> update config OnFB_SwitchToNewUserSetupModeIfNeeded
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
    fieldLens .signInModel (\s b -> { b | signInModel = s })


firebaseModel : Field FirebaseModel (SubModel model)
firebaseModel =
    fieldLens .firebaseModel (\s b -> { b | firebaseModel = s })


firebaseClient =
    fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


user =
    fieldLens .user (\s b -> { b | user = s })


fcmToken =
    fieldLens .fcmToken (\s b -> { b | fcmToken = s })


overFirebaseModel =
    over firebaseModel


overSignInModel : SignInModelF -> SubModelF model
overSignInModel =
    over signInModel >> overFirebaseModel


firebaseUpdateClientCmd model =
    getMaybeUserId model
        ?|> updateClientCmd model.firebaseModel.firebaseClient


firebaseSetupOnDisconnectCmd model =
    getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseModel.firebaseClient


startSyncWithFirebase =
    maybeEffect (getMaybeUserId >>? startSyncCmd)


setFCMToken fcmToken_ =
    overFirebaseModel (set fcmToken fcmToken_)
        >> overFirebaseClient (updateToken fcmToken_)


overFirebaseClient =
    over firebaseClient >> overFirebaseModel


updateFirebaseConnection =
    updateConnection >> overFirebaseClient


getMaybeUserId =
    .firebaseModel >> .user >> Firebase.Model.getMaybeUserId


setUser =
    set user >> overFirebaseModel


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


updateConnection connected client =
    { client | connected = connected }


updateToken token client =
    { client | token = token }
