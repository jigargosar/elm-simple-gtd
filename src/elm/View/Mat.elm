module View.Mat exposing (..)

import Mat exposing (..)
import Model.Msg
import Msg


newTodoFab m =
    Mat.fab Msg.OnMdl
        m.mdl
        [ id "add-fab"
        , primaryFABCS
        , resourceId "add-todo-fab"
        , onClickStopPropagation (Model.Msg.onNewTodoModeWithFocusInEntityAsReference m)
        ]
        [ icon "add" ]
