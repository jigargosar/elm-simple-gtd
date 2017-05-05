module Firebase exposing (..)

import Json.Decode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import WebComponents exposing (onPropertyChanged)


type alias UserModel =
    { id : String
    }


type User
    = NotLoggedIn
    | LoggedIn UserModel


userDecoder =
    Json.Decode.succeed NotLoggedIn


onUserChanged =
    onPropertyChanged "user" userDecoder
