module Routes exposing (..)

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
            [ "lists", "all" ]

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        ProjectListView ->
            [ "lists", "projects" ]

        ProjectView projectId ->
            [ "project", projectId ]

        TodoContextView context ->
            [ "project", context ]


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "all" :: [] ->
            [ Msg.SetView GroupByContextView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetView ProjectListView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetView BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetView DoneView ]

        "project" :: projectId :: [] ->
            [ Msg.SetView (ProjectView projectId) ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
