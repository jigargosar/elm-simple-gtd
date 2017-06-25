module Firebase.View exposing (..)

import Firebase exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Html exposing (onClickStopPropagation)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
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
            , onUserChanged Model.OnSetUser
            ]
            []
         , Html.node "firebase-messaging"
            [ id "fb-messaging"
            , onFCMTokenChanged Model.OnFCMTokenChanged
            , customSw
            ]
            []
         , Html.node "firebase-document"
            [ attribute "path" ".info/connected"
            , onConnectionChange Model.OnFirebaseConnectionChanged
            ]
            []
         ]
        )
