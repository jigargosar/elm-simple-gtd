module View.Frame exposing (..)

import List.Extra as List
import Material.Options exposing (..)
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import View.Layout
import View.NewTodoFab
import View.Overlays
import X.Function exposing (..)
import X.Function.Infix exposing (..)


frame frameVM =
    div [ cs "mdl-typography--body-1" ]
        ([ View.Layout.appLayoutView frameVM.config frameVM frameVM.pageContent
         , View.NewTodoFab.newTodoFab frameVM.config frameVM.model
         ]
            ++ View.Overlays.overlayViews frameVM.config frameVM.model
        )
