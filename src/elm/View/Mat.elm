module View.Mat exposing (..)

import Mat exposing (..)
import Model.ExMode
import Msg


newTodoFab m =
    Mat.fab Msg.OnMdl
        m.mdl
        [ id "add-fab"
        , primaryFABCS
        , resourceId "add-todo-fab"
        , onClickStopPropagation (Model.ExMode.onNewTodoModeWithFocusInEntityAsReference m)
        ]
        [ icon "add" ]
