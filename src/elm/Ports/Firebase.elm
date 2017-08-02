port module Ports.Firebase exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.User
import Json.Encode as E


port onFirebaseUserChanged : (E.Value -> msg) -> Sub msg


port onFCMTokenChanged : (E.Value -> msg) -> Sub msg


port onFirebaseConnectionChanged : (Bool -> msg) -> Sub msg


port signIn : () -> Cmd msg


port signOut : () -> Cmd msg


port firebaseRefSet : ( String, E.Value ) -> Cmd msg


port firebaseRefPush : ( String, E.Value ) -> Cmd msg


port fireStartSync : String -> Cmd msg


port firebaseSetupOnDisconnect : ( Data.User.UID, DeviceId ) -> Cmd msg
