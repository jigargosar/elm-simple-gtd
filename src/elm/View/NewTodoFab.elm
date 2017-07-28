module View.NewTodoFab exposing (..)

import Color
import Html exposing (text)
import Mat exposing (..)
import Material.Button
import Material.Options exposing (div)
import Material.Tooltip


--newTodoFab : ViewConfig msg -> AppModel -> Html msg


newTodoFab config m =
    div [ cs "primary-fab-container" ]
        [ div [ Material.Tooltip.attach config.onMdl [ 0 ] ]
            [ Mat.fab config.onMdl
                m.mdl
                [ id "add-fab"
                , Material.Button.colored
                , onClickStopPropagation
                    config.onStartAddingTodoWithFocusInEntityAsReference
                , resourceId "add-todo-fab"
                ]
                [ iconM { name = "add", color = Color.white } ]
            ]
        , Material.Tooltip.render config.onMdl
            [ 0 ]
            m.mdl
            [ Material.Tooltip.left ]
            [ div [ cs "mdl-typography--body-2" ] [ text "Quick Add Task (q)" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox (i)" ]
            ]
        ]
