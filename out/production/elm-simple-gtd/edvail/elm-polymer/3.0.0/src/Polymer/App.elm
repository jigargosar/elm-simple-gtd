module Polymer.App
    exposing
        ( drawer
        , drawerLayout
        , header
        , headerLayout
        , route
        , toolbar
        )

{-|
@docs drawer
@docs drawerLayout
@docs header
@docs headerLayout
@docs route
@docs toolbar
-}

import Html exposing (Attribute, Html, node)


app : String -> List (Attribute msg) -> List (Html msg) -> Html msg
app name =
    "app-" ++ name |> node


{-| -}
drawer : List (Attribute msg) -> List (Html msg) -> Html msg
drawer =
    app "drawer"


{-| -}
drawerLayout : List (Attribute msg) -> List (Html msg) -> Html msg
drawerLayout =
    app "drawer-layout"


{-| -}
header : List (Attribute msg) -> List (Html msg) -> Html msg
header =
    app "header"


{-| -}
headerLayout : List (Attribute msg) -> List (Html msg) -> Html msg
headerLayout =
    app "header-layout"


{-| -}
route : List (Attribute msg) -> List (Html msg) -> Html msg
route =
    app "route"


{-| -}
toolbar : List (Attribute msg) -> List (Html msg) -> Html msg
toolbar =
    app "toolbar"
