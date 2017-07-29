module Firebase exposing (..)

import Firebase.Model as Model


type alias UID =
    String


init =
    Model.init


getMaybeUserProfile =
    .firebaseModel >> .user >> Model.getMaybeUserProfile


updateConnection connected client =
    { client | connected = connected }


updateToken token client =
    { client | token = token }


type alias AppAttributes =
    List ( String, String )
