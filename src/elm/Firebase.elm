module Firebase exposing (..)

import Firebase.Model as Model


type alias UID =
    String


init =
    Model.init


getMaybeUserProfile =
    .firebaseModel >> .user >> Model.getMaybeUserProfile


type alias AppAttributes =
    List ( String, String )
