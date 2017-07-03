module CustomSync exposing (..)

import X.Keyboard exposing (onKeyDownStopPropagation)
import Material
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
                [ h5 [ class "layout horizontal center" ] [ Material.iconD "settings", text "Advance Settings" ]
                , p [] [ text "Sync your data with any CouchDB compatible server" ]
                , div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.noop) ]
                    [ input
                        [ defaultValue form.uri
                        , autofocus True
                        , onInput (Model.UpdateRemoteSyncFormUri form)
                        ]
                        []
                    , label [ class "active" ] [ text "Cloudant or any CouchDB URL" ]
                    ]
                , div []
                    [ Material.button "Sync Now" [ form |> Model.RemotePouchSync >> onClick ]
                    ]
                ]
            ]
