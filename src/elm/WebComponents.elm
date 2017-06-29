module WebComponents exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Material
import Polymer.Attributes exposing (boolProperty)
import Polymer.Paper
import String.Extra
import X.Html exposing (onClickStopPropagation)


iconA =
    attribute "icon"


dynamicAlign =
    boolProperty "dynamicAlign" True


slotDropdownTrigger =
    attribute "slot" "dropdown-trigger"


slotDropdownContent =
    attribute "slot" "dropdown-content"


onBoolPropertyChanged propertyName tagger =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map tagger (Json.Decode.at [ "detail", "value" ] Json.Decode.bool))


onPropertyChanged propertyName decoder tagger =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map tagger (Json.Decode.at [ "detail", "value" ] decoder))


onStringPropertyChanged propertyName tagger =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map tagger (Json.Decode.at [ "detail", "value" ] Json.Decode.string))


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    on "change" (Json.Decode.map tagger targetValue)
