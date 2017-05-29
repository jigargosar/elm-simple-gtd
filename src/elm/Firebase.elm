port module Firebase exposing (..)

import Html.Attributes.Extra exposing (boolProperty)
import Json.Decode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import WebComponents exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Json.Encode.Extra as E
import Time exposing (Time)


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port fireDataWrite : ( String, E.Value ) -> Cmd msg


port fireDataPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port onFirebaseChange : (( String, E.Value ) -> msg) -> Sub msg


onChange tagger =
    onFirebaseChange (uncurry tagger)


startSyncCmd =
    fireStartSync


type alias UserModel =
    { id : String
    , providerData : List ProviderData
    }


type alias ProviderData =
    { displayName : String
    , email : String
    , photoURL : String
    , providerId : String
    , uid : String
    }


type alias Client =
    { id : String
    , connected : Bool
    , token : Maybe String
    }


initClient deviceId =
    { id = deviceId, connected = False, token = Nothing }


providerDataDecoder =
    D.succeed ProviderData
        |> D.required "displayName" D.string
        |> D.required "email" D.string
        |> D.required "photoURL" D.string
        |> D.required "providerId" D.string
        |> D.required "uid" D.string


type User
    = NotLoggedIn
    | LoggedIn UserModel


userDecoder : Decoder User
userDecoder =
    D.oneOf
        [ D.succeed UserModel
            |> D.required "uid" D.string
            |> D.required "providerData" (D.list providerDataDecoder)
            |> D.map LoggedIn
        , D.succeed NotLoggedIn
        ]


onUserChanged =
    onPropertyChanged "user" userDecoder


fcmTokenDecoder : Decoder FCMToken
fcmTokenDecoder =
    D.nullable D.string


onFCMTokenChanged =
    onPropertyChanged "token" fcmTokenDecoder


onConnectionChange =
    onBoolPropertyChanged "data"


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


updateTokenCmd deviceId fcmToken uid =
    fireDataWrite ( "/users/" ++ uid ++ "/tokens/" ++ deviceId, encodeFCMToken fcmToken )


updateClientCmd client uid =
    fireDataWrite ( "/users/" ++ uid ++ "/clients/" ++ client.id, encodeClient client )


scheduledReminderNotificationCmd : Maybe Time -> String -> String -> Cmd msg
scheduledReminderNotificationCmd maybeTime uid todoId =
    let
        value =
            maybeTime
                ?|> (\time ->
                        E.object
                            [ "todoId" => E.string todoId
                            , "uid" => E.string uid
                            , "timestamp" => E.float time
                            ]
                    )
                ?= E.null
    in
        fireDataWrite ( "/notifications/" ++ uid ++ "---" ++ todoId, value )
