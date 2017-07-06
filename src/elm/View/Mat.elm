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
    Mat.fab m.mdl
        [ id "add-fab"
        , primaryFABCS
        , resourceId "add-todo-fab"
        , onClickStopPropagation (Model.onNewTodoModeWithFocusInEntityAsReference m)
        ]
        [ icon "add" ]
