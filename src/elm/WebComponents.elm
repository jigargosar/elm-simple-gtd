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


ironIcon =
    Html.node "iron-icon"


iconA =
    attribute "icon"


paperIconButton =
    Html.node "paper-icon-button"


iconButton iconName attributes =
    paperIconButton (attributes ++ [ iconA iconName ]) []


doneAllIconP =
    iconA "done-all"


secondaryA =
    attribute "secondary" "true"


dynamicAlign =
    boolProperty "dynamicAlign" True


slotDropdownTrigger =
    attribute "slot" "dropdown-trigger"


slotDropdownContent =
    attribute "slot" "dropdown-content"


labelA =
    attribute "label"


selectedA =
    attribute "selected"


noLabelFloatP =
    boolProperty "noLabelFloatP" True


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
