module Model.Internal exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (ModelF)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (set)


editMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setEditMode : ExclusiveMode -> ModelF
setEditMode =
    set editMode
