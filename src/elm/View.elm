module View exposing (..)

import Mat exposing (cs)
import Material.Options exposing (div)
import View.Layout
import View.NewTodoFab exposing (newTodoFab)
import View.Overlays
import ViewModel


--init : ViewConfig msg -> AppModel -> Html msg


init config model =
    let
        appVM =
            ViewModel.create config model

        children =
            [ View.Layout.appLayoutView config appVM model
            , newTodoFab config model
            ]
                ++ View.Overlays.overlayViews config model
    in
    div [ cs "mdl-typography--body-1" ] children
