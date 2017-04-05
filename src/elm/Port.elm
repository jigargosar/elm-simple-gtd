module Port exposing (..)

import Dict exposing (Dict)
import Json.Encode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Tracker req res msg =
    { lastId : Int, out : Request req -> msg, handlers : Dict Int (Response res -> ()) }


type alias Request a =
    { a | portRequestId : Int }


type alias Response a =
    { portRequestId : Int }


call value handler tracker =
    let
        id =
            tracker.lastId

        newTracker =
            { tracker | lastId = id, handlers = Dict.insert id handler tracker.handlers }

        newValue =
            { value | portRequestId = id }
    in
        ( newTracker, tracker.out newValue )


handle res tracker =
    let
        handler =
            Dict.get res.portRequestId tracker.handlers

        _ =
            handler res
    in
        { tracker | handlers = Dict.remove res.portRequestId tracker.handlers }
