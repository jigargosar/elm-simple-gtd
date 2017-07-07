module CustomSync exposing (..)

import Msg
import X.Keyboard exposing (onKeyDownStopPropagation)
import Mat
import Model
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


view model =
    let
        form =
            Model.getRemoteSyncForm model
    in
        div [ id "custom-sync-container" ]
            [ div [ class "z-depth-2 static layout vertical " ]
                [ h5 [ class "layout horizontal center" ] [ Mat.icon "settings", text "Advance Settings" ]
                , p [] [ text "Sync your data with any CouchDB compatible server" ]
                , div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.noop) ]
                    [ input
                        [ defaultValue form.uri
                        , autofocus True
                        , onInput (Msg.OnUpdateRemoteSyncFormUri form)
                        ]
                        []
                    , label [ class "active" ] [ text "Cloudant or any CouchDB URL" ]
                    ]
                , div []
                    [ Mat.submit "Sync Now" [ form |> Msg.OnRemotePouchSync >> onClick ]
                    ]
                ]
            ]
