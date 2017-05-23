module Routes exposing (..)

import Document
import Entity
import Model as Model
import Msg exposing (Msg)
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
            [ Msg.SetGroupByView Entity.ContextsView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetGroupByView Entity.ProjectsView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SwitchView BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SwitchView DoneView ]

        "Inbox" :: [] ->
            [ Msg.SetGroupByView (Entity.ContextView "") ]

        "context" :: id :: [] ->
            [ Msg.SetGroupByView (Entity.ContextView id) ]

        "project" :: "NotAssigned" :: [] ->
            [ Msg.SetGroupByView (Entity.ProjectView "") ]

        "project" :: id :: [] ->
            [ Msg.SetGroupByView (Entity.ProjectView id) ]

        "notification" :: todoId :: [] ->
            [ Msg.ShowReminderOverlayForTodoId todoId ]

        "custom-sync" :: [] ->
            [ Msg.SwitchView SyncView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
