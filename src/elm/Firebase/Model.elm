module Firebase.Model exposing (..)

import Firebase.User
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E


type alias Model =
    { user : User
    , fcmToken : FCMToken
    , firebaseClient : Client
    }


init deviceId =
    { user = initUser
    , fcmToken = Nothing
    , firebaseClient = initClient deviceId
    }


type alias FCMToken =
    Maybe String


encodeFCMToken =
    E.maybe E.string


fcmTokenDecoder : Decoder FCMToken
fcmTokenDecoder =
    D.nullable D.string


type alias DeviceId =
    String


type alias Client =
    { id : DeviceId
    , connected : Bool
    , token : Maybe String
    }


initClient deviceId =
    { id = deviceId, connected = False, token = Nothing }


encodeClient client =
    E.object
        [ "id" => E.string client.id
        , "token" => E.maybe E.string client.token
        , "connected" => E.bool client.connected
        ]


type User
    = SignedOut
    | SignedIn Firebase.User.Model


initUser =
    SignedOut


userDecoder : Decoder User
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
