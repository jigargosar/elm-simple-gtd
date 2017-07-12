module View.Mat exposing (..)

import Html exposing (em, p, strong, text)
import Mat exposing (..)
import Material.Button
import Material.Options exposing (div)
import Material.Tooltip
import Material.Typography exposing (..)
import Model.Msg
import Msg


newTodoFab alv m =
    div [ cs "mdl-button--page-fab" ]
        [ div [ Material.Tooltip.attach Msg.OnMdl [ 3 ] ]
            [ Mat.fab Msg.OnMdl
                m.mdl
                [ id "add-fab"
                , Material.Button.colored
                , onClickStopPropagation (Model.Msg.onNewTodoModeWithFocusInEntityAsReference m)
                , resourceId "add-todo-fab"
                ]
                [ icon "add" ]
            ]
        , Material.Tooltip.render Msg.OnMdl
            [ 3 ]
            m.mdl
            [ Material.Tooltip.left
            , Material.Tooltip.element Html.div
            ]
            [ div
                [ cs "mdl-typography--subhead" ]
                [ text "Quick Add Task: shortcut q" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox: shortcut i" ]
            ]
        ]
