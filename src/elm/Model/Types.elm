module Model.Types exposing (..)

import Entity.Types exposing (Entity)
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias HashFocusInEntity x =
    { x
        | focusInEntity : Entity
    }
