module Subscriptions.AppDrawer exposing (..)

import AppDrawer.Types exposing (Msg(OnWindowResizeTurnOverlayOff))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Window


subscriptions _ =
    Sub.batch
        [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
