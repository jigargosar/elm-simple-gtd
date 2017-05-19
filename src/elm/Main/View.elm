module Main.View exposing (..)

import Context
import Document
import Entity.ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg exposing (Msg)
import Polymer.Paper as Paper
import Polymer.App as App
import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model

import Model exposing (Entity(..), GroupByViewType(..), MainViewType(..), Model)
import View.TodoList
import ViewModel exposing (EntityView(..))


init viewModel model =
    div [ id "main-view" ]
        ([ case Model.getMainViewType model of
            EntityListView viewType ->
                Model.createViewEntityList viewType model
                    |> (View.TodoList.listView # viewModel)

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
            ++ (overlayViews model)
        )


overlayViews m =
    contextDropdown m ++ projectDropdown m


contextDropdown : Model -> List (Html Msg)
contextDropdown model =
    let
        createListItem onItemClick context =
            Paper.item
                [ onClick (onItemClick context) ]
                [ context |> Context.getName >> text ]

        view todo =
            let
                onItemClick =
                    Msg.SetTodoContext # todo
            in
                Paper.material [ id "context-dropdown" ]
                    [ Paper.listbox []
                        (Model.getActiveContexts model .|> createListItem onItemClick)
                    ]
    in
        model |> Model.getMaybeEditTodoContextForm ?|> view |> Maybe.toList


projectDropdown : Model -> List (Html Msg)
projectDropdown model =
    let
        createListItem onItemClick project =
            Paper.item
                [ onClick (onItemClick project) ]
                [ project |> Project.getName >> text ]

        view todo =
            let
                onItemClick =
                    Msg.SetTodoProject # todo
            in
                Paper.material [ id "project-dropdown", attribute "data-prevent-default-keys" "Tab" ]
                    [ Paper.listbox []
                        (Model.getActiveProjects model .|> createListItem onItemClick)
                    ]
    in
        model |> Model.getMaybeEditTodoProjectForm ?|> view |> Maybe.toList
