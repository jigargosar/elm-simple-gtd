module Routes exposing (..)

import Document
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
            case viewType of
                ContextsView ->
                    [ "lists", "contexts" ]

                ProjectsView ->
                    [ "lists", "projects" ]

                ProjectView id ->
                    if String.isEmpty id then
                        [ "project", "NotAssigned" ]
                    else
                        [ "project", id ]

                ContextView id ->
                    if String.isEmpty id then
                        [ "Inbox" ]
                    else
                        [ "context", id ]

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
            [ Msg.SetGroupByView ContextsView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetGroupByView ProjectsView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetView BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetView DoneView ]

        "Inbox" :: [] ->
            [ Msg.SetGroupByView (ContextView "") ]

        "context" :: id :: [] ->
            [ Msg.SetGroupByView (ContextView id) ]

        "project" :: "NotAssigned" :: [] ->
            [ Msg.SetGroupByView (ProjectView "") ]

        "project" :: id :: [] ->
            [ Msg.SetGroupByView (ProjectView id) ]

        "notification" :: todoId :: [] ->
            [ Msg.ShowReminderOverlayForTodoId todoId ]

        "custom-sync" :: [] ->
            [ Msg.SetView SyncView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
