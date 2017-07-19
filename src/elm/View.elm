module View exposing (init)

import Html exposing (text)
import Material.Button
import Material.Options exposing (div)
import View.Layout
import View.Overlays
import Mat exposing (..)
import Material.Tooltip


init config appVM model =
    let
        children =
            [ View.Layout.appLayoutView config appVM model
            , newTodoFab config model
            ]
                ++ View.Overlays.overlayViews config model
    in
        div [ cs "mdl-typography--body-1" ] children


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
                [ icon "add" ]
            ]
        , Material.Tooltip.render config.onMdl
            [ 0 ]
            m.mdl
            [ Material.Tooltip.left ]
            [ div [ cs "mdl-typography--body-2" ] [ text "Quick Add Task (q)" ]
            , div [ cs "mdl-typography--body-1" ] [ text "Add To Inbox (i)" ]
            ]
        ]
