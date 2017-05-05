port module Firebase exposing (..)

import Json.Decode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import WebComponents exposing (onPropertyChanged)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


port login : () -> Cmd msg


type alias UserModel =
    { id : String
    , providerData : List ProviderData
    }


type alias ProviderData =
    { displayName : String
    , email : String
    , photoUrl : String
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
