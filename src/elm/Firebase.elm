module Firebase exposing (..)

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


type alias UserModel =
    { id : String
    }


type User
    = NotLoggedIn
    | LoggedIn UserModel


userDecoder : Decoder User
userDecoder =
    D.oneOf
        [ D.succeed UserModel
            |> D.required "uid" D.string
            |> D.map LoggedIn
        , D.succeed NotLoggedIn
        ]


onUserChanged =
    onPropertyChanged "user" userDecoder
