module Main.Routing exposing (..)

import Main.Model exposing (Model)
import Main.Msg as Msg exposing (Msg)
import Navigation exposing (Location)
import RouteUrl.Builder as Builder exposing (..)
import Function exposing ((>>>), (<<<))
import RouteUrl exposing (UrlChange)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath [ current.viewState |> toString ]
        |> Just


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        "list"::[] ->
            Msg.OnShowTodoList
        "process-inbasket"::[] ->
                    Msg.OnProcessInBasket

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
