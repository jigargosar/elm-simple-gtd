module Model.Internal exposing (..)

import ExclusiveMode.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel, ModelF)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (set)


exclusiveMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setExclusiveMode : ExclusiveMode -> ModelF
setExclusiveMode =
    set exclusiveMode


deactivateEditingMode =
    setExclusiveMode XMNone
