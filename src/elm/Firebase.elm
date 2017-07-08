port module Firebase exposing (..)

import Firebase.Model as Model
import Firebase.User
import Json.Decode
import X.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Json.Encode.Extra as E
import X.Html


type alias UID =
    String


type alias FCMToken =
    Model.FCMToken


type alias Client =
    Model.Client


type alias User =
    Model.User


type alias DeviceId =
    Model.DeviceId


init =
    Model.init


getMaybeUserProfile =
    .user >> Model.getMaybeUserProfile


updateConnection connected client =
    { client | connected = connected }


updateToken token client =
    { client | token = token }


customSw =
    X.Html.boolProperty "customSw" True


type alias AppAttributes =
    List ( String, String )
