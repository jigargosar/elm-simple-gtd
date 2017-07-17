module Msg.ExclusiveMode exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode)


type ExclusiveModeMsg
    = OnSetExclusiveMode ExclusiveMode
    | OnSetExclusiveModeToNoneAndTryRevertingFocus
    | OnSaveExclusiveModeForm
