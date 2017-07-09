port module Firebase exposing (..)

import Firebase.Model as Model
import X.Html


type alias UID =
    String


type alias Client =
    Model.Client


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
