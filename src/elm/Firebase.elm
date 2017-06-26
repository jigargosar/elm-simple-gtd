port module Firebase exposing (..)

import Firebase.User
import Json.Decode
import Polymer.Attributes exposing (boolProperty)
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E


type Msg
    = OnSignIn
    | OnSignOut
    | AfterUserChanged
    | OnSkipSignIn


type alias UID =
    String


type alias DeviceId =
    String


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( UID, DeviceId ) -> Cmd msg


port onFirebaseChange : (( String, E.Value ) -> msg) -> Sub msg


onChange tagger =
    onFirebaseChange (uncurry tagger)


setupOnDisconnectCmd client uid =
    firebaseSetupOnDisconnect ( uid, client.id )


startSyncCmd =
    fireStartSync


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
    boolProperty "customSw" True


type alias AppAttributes =
    List ( String, String )


updateClientCmd client uid =
    firebaseRefSet ( "/users/" ++ uid ++ "/clients/" ++ client.id, encodeClient client )
