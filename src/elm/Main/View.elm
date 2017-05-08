module Main.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import Polymer.Paper as Paper
import Polymer.App as App
import Test.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model
import Model.Types exposing (MainViewType(..))
import View.TodoList


init viewModel model =
    let
        projectVMs =
            viewModel.projects.entityList

        contextVMs =
            viewModel.contexts.entityList
    in
        div [ id "main-view" ]
            [ case Model.getMainViewType model of
                GroupByContextView ->
                    View.TodoList.groupByContext viewModel model

                GroupByProjectView ->
                    View.TodoList.groupByProject viewModel model

                ProjectView id ->
                    View.TodoList.groupByEntityWithId viewModel projectVMs id model

                ContextView id ->
                    View.TodoList.groupByEntityWithId viewModel contextVMs id model

                BinView ->
                    View.TodoList.filtered model

                DoneView ->
                    View.TodoList.filtered model

                SyncView ->
                    let
                        form =
                            Model.getRemoteSyncForm model
                    in
                        Paper.material [ class "static layout vertical" ]
                            [ Paper.input
                                [ attribute "label" "Cloudant URL or any CouchDB URL"
                                , value form.uri
                                , onInput (Msg.UpdateRemoteSyncFormUri form)
                                ]
                                []
                            , div []
                                [ Paper.button [ form |> Msg.RemotePouchSync >> onClick ] [ text "Sync" ]
                                ]
                            ]

                TestView ->
                    Test.View.init model.testModel
            ]
