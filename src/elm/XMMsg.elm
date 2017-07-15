module XMMsg exposing (..)

import Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


onSetExclusiveModeToNoneAndTryRevertingFocus =
    Msg.OnSetExclusiveModeToNoneAndTryRevertingFocus |> Msg.OnExclusiveModeMsg


onSetExclusiveMode =
    Msg.OnSetExclusiveMode >> Msg.OnExclusiveModeMsg


onSaveExclusiveModeForm =
    Msg.OnSaveExclusiveModeForm |> Msg.OnExclusiveModeMsg
