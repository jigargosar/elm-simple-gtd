module Main.Routing exposing (..)

import Main.Model as Model exposing (Model)
import Main.Msg as Msg exposing (Msg)
import Main.Types exposing (ViewType(..))
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import RouteUrl exposing (UrlChange)
import FunctionExtra.Operators exposing (..)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath (getPathFromModel current)
        |> Just


getPathFromModel model =
    case Model.getViewState model of
        AllByGroupView ->
            [ "lists", "all" ]

        BinView ->
            [ "lists", "bin" ]

        DoneView ->
            [ "lists", "done" ]

        _ ->
            []


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: "all" :: [] ->
            [ Msg.SetView AllByGroupView ]

        "lists" :: "bin" :: [] ->
            [ Msg.SetView BinView ]

        "lists" :: "done" :: [] ->
            [ Msg.SetView DoneView ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
