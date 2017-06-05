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


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getMainViewType model of
        EntityListView viewType ->
            Entity.routes viewType

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        SyncView ->
            [ "custom-sync" ]


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "contexts" :: [] ->
            [ Model.SetGroupByView Entity.ContextsView ]

        "lists" :: "projects" :: [] ->
            [ Model.SetGroupByView Entity.ProjectsView ]

        "lists" :: "bin" :: [] ->
            [ Model.SwitchView BinView ]

        "lists" :: "done" :: [] ->
            [ Model.SwitchView DoneView ]

        "Inbox" :: [] ->
            [ Model.SetGroupByView (Entity.ContextView "") ]

        "context" :: id :: [] ->
            [ Model.SetGroupByView (Entity.ContextView id) ]

        "project" :: "NotAssigned" :: [] ->
            [ Model.SetGroupByView (Entity.ProjectView "") ]

        "project" :: id :: [] ->
            [ Model.SetGroupByView (Entity.ProjectView id) ]

        "notification" :: todoId :: [] ->
            [ Model.ShowReminderOverlayForTodoId todoId ]

        "custom-sync" :: [] ->
            [ Model.SwitchView SyncView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
