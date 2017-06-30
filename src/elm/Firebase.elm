port module Firebase exposing (..)

import Firebase.User
import Json.Decode
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import X.Html


type Msg
    = NOOP
    | OnSignIn
    | OnSignOut
    | AfterUserChanged
    | OnSkipSignIn
    | OnUserChanged E.Value
    | OnFCMTokenChanged FCMToken
    | OnFirebaseConnectionChanged Bool


type alias UID =
    String


type alias DeviceId =
    String


type alias Client =
    { id : DeviceId
    , connected : Bool
    , token : Maybe String
    }


initClient deviceId =
    { id = deviceId, connected = False, token = Nothing }


type User
    = SignedOut
    | SignedIn Firebase.User.Model


userDecoder : Decoder User
userDecoder =
    D.oneOf
        [ Firebase.User.decoder |> D.map SignedIn
        , D.succeed SignedOut
        ]


fcmTokenDecoder : Decoder FCMToken
fcmTokenDecoder =
    D.nullable D.string


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


getPhotoURL =
    .photoURL


type alias FCMToken =
    Maybe String


encodeFCMToken =
    E.maybe E.string


encodeClient client =
    E.object
        [ "id" => E.string client.id
        , "token" => E.maybe E.string client.token
        , "connected" => E.bool client.connected
        ]


updateConnection connected client =
    { client | connected = connected }


updateToken token client =
    { client | token = token }


customSw =
    X.Html.boolProperty "customSw" True


type alias AppAttributes =
    List ( String, String )
