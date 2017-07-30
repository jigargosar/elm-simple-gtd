module View.CustomSync exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMCustomSync))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import Toolkit.Operators exposing (..)
import X.Keyboard exposing (onKeyDownStopPropagation)


view config model =
    let
        form =
            let
                maybeForm =
                    case model.editMode of
                        XMCustomSync form ->
                            Just form

                        _ ->
                            Nothing
            in
            maybeForm ?= { uri = model.pouchDBRemoteSyncURI }
    in
    div [ id "custom-sync-container" ]
        [ div [ class "z-depth-2 static layout vertical " ]
            [ h5 [ class "layout horizontal center" ]
                [ Mat.icon "settings"
                , text "Advance Settings"
                ]
            , p [] [ text "Sync your data with any CouchDB compatible server" ]
            , div
                [ class "input-field"
                , onKeyDownStopPropagation (\_ -> config.noop)
                ]
                [ input
                    [ defaultValue form.uri
                    , autofocus True
                    , onInput (config.onUpdateCustomSyncFormUri form)
                    ]
                    []
                , label [ class "active" ] [ text "Cloudant or any CouchDB URL" ]
                ]
            , div []
                [ Mat.submit "Sync Now"
                    [ form |> config.onStartCustomRemotePouchSync >> onClick ]
                ]
            ]
        ]
