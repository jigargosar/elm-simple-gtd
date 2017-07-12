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


editMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


setEditMode : ExclusiveMode -> ModelF
setEditMode =
    set editMode


setTodoEXMode : XMTodoType -> ModelF
setTodoEXMode =
    XMTodo >> set editMode


setTodoEditForm f m =
    { m | maybeTodoEditForm = Just f }


updateEditModeM : (AppModel -> ExclusiveMode) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


deactivateEditingMode =
    setEditMode XMNone
