module Model.Keyboard exposing (..)

import Keyboard.Combo
import Types exposing (AppModel, ModelF, ModelReturnF)
import X.Keyboard exposing (KeyboardState)
import X.Record exposing (over, overReturn)


keyboardState =
    X.Record.field .keyboardState (\s b -> { b | keyboardState = s })


keyComboModel =
    X.Record.field .keyComboModel (\s b -> { b | keyComboModel = s })


updateKeyboardState : (KeyboardState -> KeyboardState) -> ModelF
updateKeyboardState =
    over keyboardState


updateCombo : Keyboard.Combo.Msg -> ModelReturnF
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)
