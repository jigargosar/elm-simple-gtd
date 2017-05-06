module Firebase.View exposing (..)

import Firebase exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Msg exposing (commonMsg)
import WebComponents exposing (..)


attributes =
    List.map (uncurry attribute)


createAppAttributes =
    attributes
        [ "database-url" => "https://rational-mote-664.firebaseio.com"
        , "api-key" => "AIzaSyASFVPlWjIrpgSlmlEEIMZ0dtPFOuRC0Hc"
        , "messaging-sender-id" => "49437522774"
        , "auth-domain" => "rational-mote-664.firebaseapp.com"
        ]


init m =
    div [ id "firebase-container" ]
        [ Html.node "firebase-app" createAppAttributes []
        , Html.node "firebase-auth"
            [ id "google-auth"
            , attribute "provider" "google"
            , onUserChanged Msg.OnFirebaseUserChanged
            ]
            []
        , Html.node "firebase-messaging"
            [ id "fb-messaging"
            , onFCMTokenChanged Msg.SetFCMToken
            , customSw
            ]
            []
        ]
