module Firebase.Model exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.User exposing (MaybeUser)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)


type alias FirebaseModel =
    { maybeUser : MaybeUser
    , fcmToken : FCMToken
    , firebaseClient : FirebaseClient
    , showSignInDialog : Bool
    }


type alias FCMToken =
    Maybe String


type alias FirebaseClient =
    { id : DeviceId
    , connected : Bool
    , token : Maybe String
    }


initialValue : String -> E.Value -> FirebaseModel
initialValue deviceId initialOfflineStore =
    let
        showSignInDialog =
            D.decodeValue (D.field "showSignInDialog" D.bool) initialOfflineStore
                |> Debug.log "showSignInDialog decoded"
                != True
    in
    { maybeUser = Nothing
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


getMaybeUserId maybeUser =
    maybeUser ?|> .id


getMaybeUser =
    .maybeUser
