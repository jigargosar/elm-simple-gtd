module Main.View exposing (..)

import Context
import Document
import EntityList.View
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
import View.TodoList


init viewModel model =
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


createProjectMenuViewModel : Model -> Todo.Model -> Menu.ViewModel Project.Model Msg
createProjectMenuViewModel model todo =
    { items = Model.getActiveProjects model
    , onSelect = Model.SetTodoProject # todo
    , isSelected = Document.hasId (Todo.getProjectId todo)
    , itemDomId = Document.getId >> String.append "project-id-"
    , domId = "project-menu"
    , itemView = Project.getName >> text
    }


projectMenu : Model -> List (Html Msg)
projectMenu model =
    model
        |> Model.getMaybeEditTodoProjectForm
        ?|> (createProjectMenuViewModel model >> Menu.view)
        |> Maybe.toList


createContextMenuViewModel : Model -> Todo.Model -> Menu.ViewModel Context.Model Msg
createContextMenuViewModel model todo =
    { items = Model.getActiveContexts model
    , onSelect = Model.SetTodoContext # todo
    , isSelected = Document.hasId (Todo.getContextId todo)
    , itemDomId = Document.getId >> String.append "context-id-"
    , domId = "context-menu"
    , itemView = Context.getName >> text
    }


contextMenu : Model -> List (Html Msg)
contextMenu model =
    model
        |> Model.getMaybeEditTodoContextForm
        ?|> (createContextMenuViewModel model >> Menu.view)
        |> Maybe.toList
