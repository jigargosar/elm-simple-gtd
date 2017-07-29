module Subscriptions.Firebase exposing (..)

import Ports.Firebase exposing (..)
import Types.Firebase exposing (..)


subscriptions : model -> Sub FirebaseMsg
subscriptions _ =
    Sub.batch
        [ onFirebaseUserChanged OnFBUserChanged
        , onFCMTokenChanged OnFBFCMTokenChanged
        , onFirebaseConnectionChanged OnFBConnectionChanged
        ]
