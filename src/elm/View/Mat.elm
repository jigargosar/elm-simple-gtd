module View.Mat exposing (..)

import Mat exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model


newTodoFab m =
    btn m.mdl
        [ id "add-fab"
        , primaryFAB
        , resourceId "add-todo-fab"
        , onClickStopPropagation (Model.foo m)
        ]
        [ icon "add" ]
