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
        AllByTodoContextView ->
            [ "lists", "all" ]

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        ProjectListView ->
            [ "lists", "projects" ]

        ProjectView project ->
            [ "project", Project.getId project ]


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "all" :: [] ->
            [ Msg.SetMainViewType AllByTodoContextView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetMainViewType ProjectListView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetMainViewType BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetMainViewType DoneView ]

        "project" :: projectId :: [] ->
            [ Msg.SetMainViewType (ProjectView projectId) ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
