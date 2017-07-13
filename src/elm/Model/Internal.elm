module Model.Internal exposing (..)

import ExclusiveMode.Types exposing (..)
import Types exposing (AppModel, ModelF)
import X.Record exposing (set)


exclusiveMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setExclusiveMode : ExclusiveMode -> ModelF
setExclusiveMode =
    set exclusiveMode


deactivateEditingMode =
    setExclusiveMode XMNone
