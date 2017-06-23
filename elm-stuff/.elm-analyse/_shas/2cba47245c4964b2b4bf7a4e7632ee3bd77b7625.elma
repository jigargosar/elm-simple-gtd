module Polymer.Attributes
    exposing
        ( attrForSelected
        , boolProperty
        , icon
        , label
        , path
        , selected
        , stringProperty
        )

{-|
@docs attrForSelected
@docs boolProperty
@docs icon
@docs label
@docs path
@docs selected
@docs stringProperty
-}

import Html exposing (Attribute)
import Html.Attributes exposing (property)
import Json.Encode exposing (string, bool)


{-| -}
attrForSelected : String -> Attribute msg
attrForSelected =
    stringProperty "attrForSelected"


{-| -}
boolProperty : String -> Bool -> Attribute msg
boolProperty name value =
    bool value |> property name


{-| -}
icon : String -> Attribute msg
icon =
    stringProperty "icon"


{-| -}
label : String -> Attribute msg
label =
    stringProperty "label"


{-| -}
path : String -> Attribute msg
path =
    stringProperty "path"


{-| -}
selected : String -> Attribute msg
selected =
    stringProperty "selected"


{-| -}
stringProperty : String -> String -> Attribute msg
stringProperty name value =
    string value |> property name
