module Firebase.View exposing (..)

import Firebase exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Model
import WebComponents exposing (..)


attributes =
    List.map (uncurry attribute)


onFCMTokenChanged =
    onPropertyChanged "token" fcmTokenDecoder


onConnectionChange =
    onBoolPropertyChanged "data"


onUserChanged =
    onPropertyChanged "user" userDecoder


init m =
    div [ id "firebase-container" ]
        ([ Html.node "firebase-auth"
            [ id "firebase-auth"
            , onUserChanged Firebase.OnUserChanged
            ]
            []
         , Html.node "firebase-messaging"
            [ id "fb-messaging"
            , onFCMTokenChanged Firebase.OnFCMTokenChanged
            , customSw
            ]
            []
         , Html.node "firebase-document"
            [ attribute "path" ".info/connected"
            , onConnectionChange Firebase.OnFirebaseConnectionChanged
            ]
            []
         ]
        )
        |> Model.OnFirebaseMsg
