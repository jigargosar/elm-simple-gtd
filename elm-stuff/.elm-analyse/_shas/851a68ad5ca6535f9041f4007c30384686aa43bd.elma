module Polymer.Firebase exposing (app)

{-|
@docs app
-}

import Html exposing (Attribute, Html, node)


firebase : String -> List (Attribute msg) -> List (Html msg) -> Html msg
firebase name =
    "firebase-" ++ name |> node


{-| -}
app : List (Attribute msg) -> List (Html msg) -> Html msg
app =
    firebase "app"
