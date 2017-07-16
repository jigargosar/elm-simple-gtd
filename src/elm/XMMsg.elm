module XMMsg exposing (..)

import Msg


onSetExclusiveModeToNoneAndTryRevertingFocus =
    Msg.OnSetExclusiveModeToNoneAndTryRevertingFocus |> Msg.OnExclusiveModeMsg


onSetExclusiveMode =
    Msg.OnSetExclusiveMode >> Msg.OnExclusiveModeMsg


onSaveExclusiveModeForm =
    Msg.OnSaveExclusiveModeForm |> Msg.OnExclusiveModeMsg
