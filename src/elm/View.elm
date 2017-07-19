module View exposing (init)

import View.Layout
import Html exposing (..)
import Html.Attributes exposing (..)
import View.Mat
import View.Overlays


init config appVM model =
    let
        children =
            [ View.Layout.appLayoutView config appVM model
            , View.Mat.newTodoFab model
            ]
                ++ View.Overlays.overlayViews config model
    in
        div [ class "mdl-typography--body-1" ] children
