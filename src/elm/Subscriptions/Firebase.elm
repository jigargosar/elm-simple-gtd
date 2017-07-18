module Subscriptions.Firebase exposing (..)

import Firebase.Types exposing (FirebaseMsg(..))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Ports.Firebase exposing (..)


subscriptions : model -> Sub FirebaseMsg
subscriptions _ =
    Sub.batch
        [ onFirebaseUserChanged OnFBUserChanged
        , onFCMTokenChanged OnFBFCMTokenChanged
        , onFirebaseConnectionChanged OnFBConnectionChanged
        ]
