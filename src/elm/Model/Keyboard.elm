module Model.Keyboard exposing (..)

import Keyboard.Combo
import Types exposing (AppModel, ModelF, ModelReturnF)
import X.Record exposing (over, overReturn)


keyComboModel =
    X.Record.fieldLens .keyComboModel (\s b -> { b | keyComboModel = s })


updateCombo : Keyboard.Combo.Msg -> ModelReturnF
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)
