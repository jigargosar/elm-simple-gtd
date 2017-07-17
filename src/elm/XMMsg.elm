module XMMsg exposing (..)

import Msg
import Msg.ExclusiveMode exposing (..)


revertExclusiveMode =
    OnSetExclusiveModeToNoneAndTryRevertingFocus |> Msg.OnExclusiveModeMsg


onSetExclusiveMode =
    OnSetExclusiveMode >> Msg.OnExclusiveModeMsg


onSaveExclusiveModeForm =
    OnSaveExclusiveModeForm |> Msg.OnExclusiveModeMsg
