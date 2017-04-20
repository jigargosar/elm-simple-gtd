module Routes exposing (..)

import Document
import Model as Model
import Model.Internal as Model
import Msg exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import RouteUrl exposing (UrlChange)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)
import Project


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getMainViewType model of
        GroupByContextView ->
            [ "lists", "contexts" ]

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        GroupByProjectView ->
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


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "contexts" :: [] ->
            [ Msg.SetView GroupByContextView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetView GroupByProjectView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetView BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetView DoneView ]

        "project" :: "NotAssigned" :: [] ->
            [ Msg.SetView (ProjectView "") ]

        "project" :: id :: [] ->
            [ Msg.SetView (ProjectView id) ]

        "context" :: id :: [] ->
            [ Msg.SetView (ContextView id) ]

        "Inbox" :: [] ->
            [ Msg.SetView (ContextView "") ]

        "notification" :: todoId :: [] ->
            [ Msg.ShowReminderOverlayForTodoId todoId ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
