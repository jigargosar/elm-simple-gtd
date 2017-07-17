module Msg.ExclusiveMode exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type ExclusiveModeMsg
    = OnSetExclusiveMode ExclusiveMode
    | OnSetExclusiveModeToNoneAndTryRevertingFocus
    | OnSaveExclusiveModeForm
