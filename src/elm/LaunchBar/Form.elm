module LaunchBar.Form exposing (..)

import Char
import Keyboard.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)


_ =
    1


type alias Model =
    { input : String
    , updatedAt : Time
    }


create now =
    { input = ""
    , updatedAt = now
    }


updateInput input model now =
    { model | input = input }
        |> (\model -> { model | updatedAt = now })
