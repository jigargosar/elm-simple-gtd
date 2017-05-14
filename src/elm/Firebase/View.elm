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
    let
        encodedUserId =
            Model.getMaybeUserId m |> E.maybe E.string

        encodedToken =
            E.maybe E.string m.fcmToken

        updateTokenHelp uid =
            Html.node "firebase-document"
                [ attribute "path" ("/users/" ++ uid ++ "/token")
                , property "value" encodedToken
                ]
                []

        updateToken =
            Model.getMaybeUserId m
                ?|> (updateTokenHelp >> List.singleton)
                ?= []
    in
        div [ id "firebase-container" ]
            ([ Html.node "firebase-app" (attributes m.firebaseAppAttributes) []
             , Html.node "firebase-auth"
                [ id "google-auth"
                , attribute "provider" "google"
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
             --                ++ updateToken
            )
