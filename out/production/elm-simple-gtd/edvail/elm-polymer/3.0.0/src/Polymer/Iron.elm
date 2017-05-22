module Polymer.Iron exposing (selector)

{-|
@docs selector
-}

import Html exposing (Attribute, Html, node)


iron : String -> List (Attribute msg) -> List (Html msg) -> Html msg
iron name =
    "iron-" ++ name |> node


{-| -}
selector : List (Attribute msg) -> List (Html msg) -> Html msg
selector =
    iron "selector"
