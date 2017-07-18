port module Ports.Firebase exposing (..)

import Firebase
import Firebase.Types
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


port onFirebaseUserChanged : (E.Value -> msg) -> Sub msg


port onFCMTokenChanged : (E.Value -> msg) -> Sub msg


port onFirebaseConnectionChanged : (Bool -> msg) -> Sub msg


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( Firebase.UID, Firebase.Types.DeviceId ) -> Cmd msg
