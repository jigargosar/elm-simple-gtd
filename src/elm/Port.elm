module Port exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


_ =
    1


type alias Tracker req msg =
    { lastId : Int, out : Request req -> msg }


type alias Request a =
    { a | portRequestId : Int }


call value tracker =
    let
        id =
            tracker.lastId

        newTracker =
            { tracker | lastId = id }

        newValue =
            { value | portRequestId = id }
    in
        ( newTracker, tracker.out newValue )
