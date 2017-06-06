module Main.View exposing (..)

import Context
import Document
import EntityList.View
import OldGroupEntity.ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Model exposing (Msg)
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
import Model exposing (ViewType(..), Model)
import View.TodoList


init viewModel model =
    {- div
       [ class "row"

       {- , onKeyDownStopPropagation (\_ -> commonMsg.logString "sp") -}
       ]
       [ Html.form [ class "col s12" ]
           [ div [ class "row" ]
               [ div [ class "input-field col s12" ]
                   [ Html.textarea [ id "textarea1", class "materialize-textarea" ] []
                   , Html.label [ for "textarea1" ] [ text "Textarea" ]
                   ]
               ]
           ]
       ]
    -}
    div [ id "main-view" ]
        ([ case Model.getMainViewType model of
            EntityListView viewType ->
                EntityList.View.listView viewType model viewModel

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
                            , onInput (Model.UpdateRemoteSyncFormUri form)
                            ]
                            []
                        , div []
                            [ Paper.button [ form |> Model.RemotePouchSync >> onClick ]
                                [ text "Start Sync" ]
                            ]
                        ]
         ]
            ++ (overlayViews model)
        )


overlayViews m =
    contextMenu m
        ++ projectMenu m


contextMenu : Model -> List (Html Msg)
contextMenu model =
    let
        createListItem onItemClick context =
            Paper.item
                [ onClick (onItemClick context) ]
                [ context |> Context.getName >> text ]

        view todo =
            let
                onItemClick =
                    Model.SetTodoContext # todo
            in
                Paper.material [ id "context-dropdown", attribute "data-prevent-default-keys" "Tab" ]
                    [ Paper.listbox []
                        (Model.getActiveContexts model .|> createListItem onItemClick)
                    ]
    in
        model |> Model.getMaybeEditTodoContextForm ?|> view |> Maybe.toList
