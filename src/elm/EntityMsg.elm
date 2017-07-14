module EntityMsg exposing (..)

import Entity.Types exposing (EntityMsg(..), EntityUpdateAction(..))
import Msg
import Toolkit.Operators exposing (..)


onEntityIdUpdateMsg =
    Msg.onEntityUpdateMsg


onToggleEntitySelection =
    EM_Update # EUA_ToggleSelection >> Msg.OnEntityMsg


onStartEditingEntity =
    EM_Update # EUA_StartEditing >> Msg.OnEntityMsg
