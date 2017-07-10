module Model.Keyboard exposing (..)

import Keyboard.Combo
import Model exposing (keyComboModel)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Types exposing (AppModel, ModelF, ModelReturnF)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (over, overReturn)


keyboardState =
    X.Record.field .keyboardState (\s b -> { b | keyboardState = s })


updateKeyboardState : (KeyboardState -> KeyboardState) -> ModelF
updateKeyboardState =
    over keyboardState


updateCombo : Keyboard.Combo.Msg -> ModelReturnF
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)
