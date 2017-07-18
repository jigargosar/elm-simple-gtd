module Subscriptions.AppDrawer exposing (..)

import AppDrawer.Types exposing (Msg(OnWindowResizeTurnOverlayOff))
import Window


subscriptions _ =
    Sub.batch
        [ Window.resizes (\_ -> OnWindowResizeTurnOverlayOff) ]
