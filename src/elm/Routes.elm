module Routes exposing (..)

import Model as Model
import Msg exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import RouteUrl exposing (UrlChange)
import FunctionExtra.Operators exposing (..)
import Types exposing (MainViewType(..), Model)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getMainViewType model of
        AllByGroupView ->
            [ "lists", "all" ]

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        ProjectsView ->
            [ "lists", "projects" ]

        _ ->
            []


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "all" :: [] ->
            [ Msg.SetMainViewType AllByGroupView ]

        "lists" :: "projects" :: [] ->
            [ Msg.SetMainViewType ProjectsView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetMainViewType BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetMainViewType DoneView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
