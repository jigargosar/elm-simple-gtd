module Main.View exposing (..)

import Document
import Entity.ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import Polymer.Paper as Paper
import Polymer.App as App
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model
import Types exposing (Entity(..), MainViewType(..))
import View.TodoList
import ViewModel exposing (EntityView(..))


init viewModel model =
    let
        projectVMs =
            viewModel.projects.entityList

        contextVMs =
            viewModel.contexts.entityList

        getMaybeContextVM context =
            contextVMs |> List.find (.id >> equals (Document.getId context))

        getMaybeProjectVM project =
            projectVMs |> List.find (.id >> equals (Document.getId project))

        entityList =
            Model.getViewEntityList model

        entityViewList : List EntityView
        entityViewList =
            entityList
                .|> (\entity ->
                        case entity of
                            ContextEntity context ->
                                getMaybeContextVM context ?|> EntityView

                            ProjectEntity project ->
                                getMaybeProjectVM project ?|> EntityView

                            TodoEntity todo ->
                                TodoView todo |> Just
                    )
                |> List.filterMap identity
    in
        div [ id "main-view" ]
            [ case Model.getMainViewType model of
                GroupByContextView ->
                    View.TodoList.listView entityViewList viewModel model

                GroupByProjectView ->
                    View.TodoList.listView entityViewList viewModel model

                ContextView id ->
                    View.TodoList.listView entityViewList viewModel model

                ProjectView id ->
                    View.TodoList.groupByEntityWithId viewModel projectVMs id model

                BinView ->
                    View.TodoList.filtered viewModel model

                DoneView ->
                    View.TodoList.filtered viewModel model

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
            ]
