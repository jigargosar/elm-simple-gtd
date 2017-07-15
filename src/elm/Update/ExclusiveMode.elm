module Update.ExclusiveMode exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Model exposing (commonMsg)
import Msg exposing (..)
import Return exposing (map)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Types exposing (..)
import X.Record exposing (..)


update :
    (AppMsg -> ReturnF)
    -> ExclusiveModeMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnSetExclusiveMode mode ->
            setExclusiveMode mode
                |> map

        OnSetExclusiveModeToNoneAndTryRevertingFocus ->
            map setExclusiveModeToNone
                >> andThenUpdate setDomFocusToFocusInEntityCmd


exclusiveMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setExclusiveMode : ExclusiveMode -> ModelF
setExclusiveMode =
    set exclusiveMode


setExclusiveModeToNone =
    setExclusiveMode XMNone


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")
