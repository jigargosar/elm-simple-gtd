module Firebase exposing (..)

import Firebase.Model as Model


init =
    Model.initialValue


getMaybeUser =
    .firebaseModel >> .maybeUser
