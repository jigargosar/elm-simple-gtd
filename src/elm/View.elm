module View exposing (..)

import Entity.ListView
import Mat exposing (cs)
import Material.Options exposing (div)
import Page
import View.CustomSync
import View.Layout
import View.NewTodoFab exposing (newTodoFab)
import View.Overlays
import ViewModel


init config model =
    let
        appVM =
            ViewModel.create config model

        pageContent =
            case Page.getPage model of
                Page.EntityListPage entityListPageModel ->
                    Entity.ListView.listView config appVM entityListPageModel model

                Page.CustomSyncSettingsPage ->
                    View.CustomSync.view config model

        children =
            [ View.Layout.appLayoutView config appVM model pageContent
            , newTodoFab config model
            ]
                ++ View.Overlays.overlayViews config model
    in
    div [ cs "mdl-typography--body-1" ] children
