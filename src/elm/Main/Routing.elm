module Main.Routing exposing (..)

import Main.Model as Model exposing (Model)
import Main.Msg as Msg exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import Function exposing ((>>>), (<<<))
import RouteUrl exposing (UrlChange)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath [ getPathFromModel current ]
        |> Just


getPathFromModel model =
    case Model.getViewState model of
        Model.TodoListViewState ->
            "lists"

        Model.InboxFlowViewState _ _ ->
            "process-inbox"


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "lists" :: [] ->
            [ Msg.OnShowTodoList ]

        "process-inbox" :: [] ->
            [ Msg.OnProcessInbox ]

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
