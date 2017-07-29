module Firebase.Model exposing (..)

import Firebase.Types exposing (..)
import Firebase.User
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import X.Function.Infix exposing (..)


type alias Model =
    { user : FirebaseUser
    , fcmToken : FCMToken
    , firebaseClient : FirebaseClient
    }


init deviceId =
    { user = initUser
    , fcmToken = Nothing
    , firebaseClient = initClient deviceId
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
