module Model.TodoStore exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record


todoStore =
    X.Record.fieldLens .todoStore (\s b -> { b | todoStore = s })


focusInEntity =
    X.Record.fieldLens .focusInEntity (\s b -> { b | focusInEntity = s })
