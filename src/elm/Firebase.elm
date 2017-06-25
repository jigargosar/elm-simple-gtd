port module Firebase exposing (..)

import Firebase.User
import Json.Decode
import Polymer.Attributes exposing (boolProperty)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import WebComponents exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Json.Encode.Extra as E
import Time exposing (Time)


type alias UID =
    String


type alias DeviceId =
    String


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


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
    = NotLoggedIn
    | LoggedIn Firebase.User.UserModel


userDecoder : Decoder User
userDecoder =
    D.oneOf
        [ Firebase.User.decoder |> D.map LoggedIn
        , D.succeed NotLoggedIn
        ]


onUserChanged =
    onPropertyChanged "user" userDecoder


fcmTokenDecoder : Decoder FCMToken
fcmTokenDecoder =
    D.nullable D.string


getMaybeUserProfile user =
    case user of
        NotLoggedIn ->
            Nothing

        LoggedIn userModel ->
            userModel.providerData |> List.head


getMaybeUserId user =
    case user of
        NotLoggedIn ->
            Nothing

        LoggedIn userModel ->
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
