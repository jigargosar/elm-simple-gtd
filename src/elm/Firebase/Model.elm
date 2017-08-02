module Firebase.Model exposing (..)

import Firebase.SignIn
import Firebase.User
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import Types.Firebase exposing (..)
import X.Function.Infix exposing (..)


init : String -> Firebase.SignIn.SignInModel -> FirebaseModel
init deviceId signInModel =
    { user = initUser
    , fcmToken = Nothing
    , firebaseClient = initClient deviceId
    , signInModel = signInModel
    , showSignInDialog = True
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
