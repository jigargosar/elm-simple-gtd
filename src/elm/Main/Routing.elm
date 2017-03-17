module Main.Routing exposing (..)

import Main.Model exposing (Model)
import Main.Msg as Msg exposing (Msg)
import Navigation exposing (Location)
import RouteHash
import RouteUrl.Builder as Builder exposing (..)
import Function exposing ((>>>), (<<<))
import RouteUrl exposing (UrlChange)


delta2builder : Model -> Model -> Maybe Builder
delta2builder previous current =
    builder
        |> replacePath [ "0" ]
        |> Just


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash =
    delta2builder >>> Maybe.map toHashChange


builder2messages : Builder -> List Msg
builder2messages builder =
    case path builder of
        first :: rest ->
            case String.toInt first of
                Ok value ->
                    [ Msg.OnParsedUrl ]

                Err _ ->
                    -- If it wasn't an integer, then no action ... we could
                    -- show an error instead, of course.
                    []

        _ ->
            -- If nothing provided for this part of the URL, return empty list
            []


hash2messages : Location -> List Msg
hash2messages location =
    builder2messages (fromHash location.href)
