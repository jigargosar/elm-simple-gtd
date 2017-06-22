module DOM.Window exposing (..)

{-| This module contains functions for getting the dimensions and scroll
position of the `window` JavaScript object.

# Scroll
@docs scrollTop, scrollLeft

# Dimensions
@docs width, height
-}

import Native.DOM


{-| Returns the vertical scroll position of the window.
-}
scrollTop : () -> Float
scrollTop _ =
  Native.DOM.windowScrollTop ()


{-| Returns the horizontal scroll position of the window.
-}
scrollLeft : () -> Float
scrollLeft _ =
  Native.DOM.windowScrollLeft ()


{-| Returns the width of the window.
-}
width : () -> Float
width _ =
  Native.DOM.windowWidth ()


{-| Returns the height of the window.
-}
height : () -> Float
height _ =
  Native.DOM.windowHeight ()
