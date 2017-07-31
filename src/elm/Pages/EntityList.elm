module Pages.EntityList exposing (..)

import Color exposing (Color)
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias Record =
    { title : String
    , color : Color
    }


type Model
    = Model Record
