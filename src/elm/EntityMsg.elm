module EntityMsg exposing (..)

import Entity.Types exposing (EntityMsg(..), EntityUpdateMsg(..))
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
    OnEntityUpdate # OnToggleSelectedEntity >> Msg.OnEntityMsg
