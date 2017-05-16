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
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Model.Internal as Model
import Types exposing (Entity(..), GroupByViewType(..), MainViewType(..), Model)
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
    contextDropdown m


contextDropdown : Model -> List (Html Msg)
contextDropdown model =
    let
        createContextItem onItemClick context =
            Paper.item
                [ onClick (onItemClick context) ]
                [ context |> Context.getName >> text ]

        view form =
            let
                onItemClick =
                    Msg.SetTodoContext # form.todo
            in
                Paper.material [ id "context-dropdown" ]
                    [ Paper.listbox []
                        (Model.getActiveContexts model .|> createContextItem onItemClick)
                    ]
    in
        model |> Model.getMaybeEditTodoContextForm ?|> view |> Maybe.toList
