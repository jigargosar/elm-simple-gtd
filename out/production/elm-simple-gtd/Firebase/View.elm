module Firebase.View exposing (..)

import Firebase exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Msg exposing (commonMsg)
import WebComponents exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Json.Encode.Extra as E


attributes =
    List.map (uncurry attribute)


init m =
    div [ id "firebase-container" ]
        ([ Html.node "firebase-auth"
            [ id "firebase-auth"
            , onUserChanged Msg.OnUserChanged
            ]
            []
         , Html.node "firebase-messaging"
            [ id "fb-messaging"
            , onFCMTokenChanged Msg.OnFCMTokenChanged
            , customSw
            ]
            []
         ]
        )
