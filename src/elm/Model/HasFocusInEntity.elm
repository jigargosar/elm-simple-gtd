module Model.HasFocusInEntity exposing (..)

import Context
import Entity.Types exposing (Entity, createContextEntity)
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias HasFocusInEntity x =
    { x
        | focusInEntity_ : Entity
    }


init =
    createContextEntity Context.null
