module Firebase exposing (..)

import Firebase.Model as Model


init =
    Model.initialValue


getMaybeUserProfile =
    .firebaseModel >> .maybeUser
