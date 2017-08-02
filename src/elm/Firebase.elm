module Firebase exposing (..)

import Firebase.Model as Model


init =
    Model.init


getMaybeUserProfile =
    .firebaseModel >> .maybeUser
