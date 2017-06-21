module Routes exposing (..)

import Document
import Entity
import Model as Model
import Model exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import RouteUrl exposing (UrlChange)
import Ext.Function.Infix exposing (..)
import Model exposing (..)
import Project
import Todo.Msg


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getMainViewType model of
        EntityListView viewType ->
            Entity.routes viewType

        SyncView ->
            [ "custom-sync" ]


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "contexts" :: [] ->
            [ Model.OnSetEntityListView Entity.ContextsView ]

        "lists" :: "projects" :: [] ->
            [ Model.OnSetEntityListView Entity.ProjectsView ]

        "bin" :: [] ->
            [ Model.OnSetEntityListView Entity.BinView ]

        "done" :: [] ->
            [ Model.OnSetEntityListView Entity.DoneView ]

        "Inbox" :: [] ->
            [ Model.OnSetEntityListView (Entity.ContextView "") ]

        "context" :: id :: [] ->
            [ Model.OnSetEntityListView (Entity.ContextView id) ]

        "project" :: "NotAssigned" :: [] ->
            [ Model.OnSetEntityListView (Entity.ProjectView "") ]

        "project" :: id :: [] ->
            [ Model.OnSetEntityListView (Entity.ProjectView id) ]

        "custom-sync" :: [] ->
            [ Model.SwitchView SyncView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
