module Firebase.Update exposing (..)

import AppUrl
import Data.User
import ExclusiveMode.Types exposing (ExclusiveMode(XMSignInOverlay))
import Firebase.Model exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Navigation
import Ports
import Ports.Firebase exposing (..)
import Return
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)
import XUpdate
import XUpdate.Infix exposing (..)


type FirebaseMsg
    = OnFBSwitchToNewUserSetupModeIfNeeded
    | OnFBSignIn
    | OnFBSignOut
    | OnFBAfterUserChanged
    | OnFBSkipSignIn
    | OnFBUserChanged E.Value
    | OnFBFCMTokenChanged E.Value
    | OnFBConnectionChanged Bool


subscriptions =
    Sub.batch
        [ Ports.Firebase.onFirebaseUserChanged OnFBUserChanged
        , Ports.Firebase.onFCMTokenChanged OnFBFCMTokenChanged
        , Ports.Firebase.onFirebaseConnectionChanged OnFBConnectionChanged
        ]


type alias Config msg a =
    { a
        | onStartSetupAddTodo : msg
        , revertExclusiveMode : msg
        , onSetExclusiveMode : ExclusiveMode -> msg
        , isTodoStoreEmpty : Bool
    }


update :
    Config msg a
    -> FirebaseMsg
    -> FirebaseModel
    -> XUpdate.XReturn FirebaseModel FirebaseMsg msg
update config msg model =
    let
        defRet =
            XUpdate.pure model
    in
    case msg of
        OnFBSwitchToNewUserSetupModeIfNeeded ->
            let
                onSwitchToNewUserSetupModeIfNeeded =
                    if model.showSignInDialog then
                        config.onSetExclusiveMode XMSignInOverlay
                    else if config.isTodoStoreEmpty then
                        config.onStartSetupAddTodo
                    else
                        config.revertExclusiveMode
            in
            defRet |> XUpdate.addMsg onSwitchToNewUserSetupModeIfNeeded

        OnFBSignIn ->
            defRet
                +> signIn ()
                |> setAndPersistShowSignInDialogValue True
                ::> update config OnFBSwitchToNewUserSetupModeIfNeeded

        OnFBSkipSignIn ->
            defRet
                |> setAndPersistShowSignInDialogValue False
                ::> update config OnFBSwitchToNewUserSetupModeIfNeeded

        OnFBSignOut ->
            defRet
                +> signOut ()
                |> setAndPersistShowSignInDialogValue True
                +> Navigation.load AppUrl.landing

        OnFBAfterUserChanged ->
            model.maybeUser
                ?|> (\_ ->
                        defRet
                            |> setAndPersistShowSignInDialogValue False
                            ::> update config OnFBSwitchToNewUserSetupModeIfNeeded
                    )
                ?= defRet

        OnFBUserChanged encodedUser ->
            D.decodeValue Data.User.maybeUserDecoder encodedUser
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\userV ->
                        defRet
                            :> set userL userV
                            ::> update config OnFBAfterUserChanged
                            ?+:> firebaseUpdateClientCmd
                            ?+:> firebaseSetupOnDisconnectCmd
                            ?+:> (getMaybeUserId >>? startSyncCmd)
                    )
                != defRet

        OnFBFCMTokenChanged encodedToken ->
            D.decodeValue Firebase.Model.fcmTokenDecoder encodedToken
                |> Result.mapError (Debug.log "Error decoding User")
                !|> (\token ->
                        defRet
                            :> setFCMToken token
                            ?+:> firebaseUpdateClientCmd
                    )
                != defRet

        OnFBConnectionChanged connected ->
            defRet
                :> setClientConnectionStatus connected
                ?+:> firebaseUpdateClientCmd


showSignInDialogL =
    fieldLens .showSignInDialog (\s b -> { b | showSignInDialog = s })


signInModelL =
    fieldLens .signInModel (\s b -> { b | signInModel = s })


firebaseClientL =
    fieldLens .firebaseClient (\s b -> { b | firebaseClient = s })


userL =
    fieldLens .maybeUser (\s b -> { b | maybeUser = s })


fcmTokenL =
    fieldLens .fcmToken (\s b -> { b | fcmToken = s })


setAndPersistShowSignInDialogValue : Bool -> XUpdate.XReturnF FirebaseModel FirebaseMsg msg
setAndPersistShowSignInDialogValue bool ret =
    ret
        :> set showSignInDialogL bool
        +> Ports.persistToOfflineStore ( "showSignInDialog", E.bool bool )


firebaseUpdateClientCmd model =
    getMaybeUserId model
        ?|> updateClientCmd model.firebaseClient


firebaseSetupOnDisconnectCmd model =
    getMaybeUserId model
        ?|> setupOnDisconnectCmd model.firebaseClient


setFCMToken fcmToken =
    set fcmTokenL fcmToken
        >> over firebaseClientL (\client -> { client | token = fcmToken })


setClientConnectionStatus =
    setClientConnectedStatus >> over firebaseClientL


getMaybeUserId =
    .maybeUser >> Firebase.Model.getMaybeUserId


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, Firebase.Model.encodeClient client )


setClientConnectedStatus connected client =
    { client | connected = connected }
