module Main.View exposing (..)

import Context
import Document
import EntityList.View
import Ext.Keyboard exposing (onKeyDownStopPropagation)
import Menu
import OldGroupEntity.ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Model exposing (Msg)
import Polymer.Paper as Paper
import Polymer.App as App
import Project
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Model exposing (ViewType(..), Model)


init viewModel model =
    div [ id "main-content" ]
        [ case Model.getMainViewType model of
            EntityListView viewType ->
                EntityList.View.listView viewType model viewModel

            SyncView ->
                let
                    form =
                        Model.getRemoteSyncForm model
                in
                    div [ class "z-depth-2 static layout vertical" ]
                        [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.NOOP) ]
                            [ input
                                [ defaultValue form.uri
                                , autofocus True
                                , onInput (Model.UpdateRemoteSyncFormUri form)
                                ]
                                []
                            , label [ class "active" ] [ text "Cloudant or any CouchDB URL" ]
                            ]
                        , div []
                            [ Paper.button [ form |> Model.RemotePouchSync >> onClick ]
                                [ text "Sync Now" ]
                            ]
                        ]
        ]
