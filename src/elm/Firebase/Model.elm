module Firebase.Model exposing (..)

import Firebase.Types exposing (FCMToken, FirebaseUser(SignedIn, SignedOut))
import Firebase.User
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E


type alias Model =
    { user : FirebaseUser
    , fcmToken : FCMToken
    , firebaseClient : Client
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
