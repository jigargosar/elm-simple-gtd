module EntityMsg exposing (..)

import Entity.Types exposing (EntityMsg(..), EntityUpdateAction(..))
import Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


onEntityIdUpdateMsg =
    Msg.onEntityUpdateMsg


onToggleEntitySelection =
    EM_Update # EUA_ToggleSelection >> Msg.OnEntityMsg


onStartEditingEntity =
    EM_Update # EUA_StartEditing >> Msg.OnEntityMsg
