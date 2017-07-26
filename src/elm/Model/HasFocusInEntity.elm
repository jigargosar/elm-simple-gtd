module Model.HasFocusInEntity exposing (..)

import Context
import Entity.Types exposing (Entity, createContextEntity)


type alias HasFocusInEntity x =
    { x
        | focusInEntity_ : Entity
    }


init =
    createContextEntity Context.null
