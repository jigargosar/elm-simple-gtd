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


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


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


customSw =
    boolProperty "customSw" True


type alias AppAttributes =
    List ( String, String )
