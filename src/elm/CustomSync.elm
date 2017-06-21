module CustomSync exposing (..)

import Ext.Keyboard exposing (onKeyDownStopPropagation)
import Material
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Polymer.Paper


view model =
    let
        form =
            Model.getRemoteSyncForm model
    in
        div [ id "custom-sync-container" ]
            [ div [ class "z-depth-2 static layout vertical " ]
                [ h5 [ class "layout horizontal center" ] [ Material.icon "settings", text "Advance Settings" ]
                , p [] [ text "Sync your data with any CouchDB compatible server" ]
                , div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.NOOP) ]
                    [ input
                        [ defaultValue form.uri
                        , autofocus True
                        , onInput (Model.UpdateRemoteSyncFormUri form)
                        ]
                        []
                    , label [ class "active" ] [ text "Cloudant or any CouchDB URL" ]
                    ]
                , div []
                    [ Polymer.Paper.button [ form |> Model.RemotePouchSync >> onClick ]
                        [ text "Sync Now" ]
                    ]
                ]
            ]
