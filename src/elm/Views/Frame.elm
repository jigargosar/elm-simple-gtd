module Views.Frame exposing (..)

import Material.Options exposing (..)
import View.Layout
import View.NewTodoFab
import View.Overlays


frame frameVM =
    div [ cs "mdl-typography--body-1" ]
        ([ View.Layout.appLayoutView frameVM.config frameVM frameVM.pageContent
         , View.NewTodoFab.newTodoFab frameVM.config frameVM.model
         ]
            ++ View.Overlays.overlayViews frameVM.config frameVM.model
        )
