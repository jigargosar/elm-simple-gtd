module Firebase.Model exposing (..)

import Firebase.User
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types.Firebase exposing (..)
import X.Function.Infix exposing (..)


init : String -> E.Value -> FirebaseModel
init deviceId initialOfflineStore =
    let
        showSignInDialog =
            D.decodeValue (D.field "showSignInDialog" D.bool) initialOfflineStore
                |> Debug.log "showSignInDialog decoded"
                != True
    in
    { user = initUser
    , fcmToken = Nothing
    , firebaseClient = initClient deviceId
    , showSignInDialog = showSignInDialog
    }


encodeFCMToken =
    E.maybe E.string


fcmTokenDecoder : Decoder FCMToken
fcmTokenDecoder =
    D.nullable D.string


initClient deviceId =
    { id = deviceId, connected = False, token = Nothing }


encodeClient client =
    E.object
        [ "id" => E.string client.id
        , "token" => E.maybe E.string client.token
        , "connected" => E.bool client.connected
        ]


initUser =
    SignedOut


userDecoder : Decoder FirebaseUser
userDecoder =
    D.oneOf
        [ Firebase.User.decoder |> D.map SignedIn
        , D.succeed SignedOut
        ]


getMaybeUserProfile user =
    case user of
        SignedOut ->
            Nothing

        SignedIn userModel ->
            userModel.providerData |> List.head


getMaybeUserId user =
    case user of
        SignedOut ->
            Nothing

        SignedIn userModel ->
            userModel.id |> Just
