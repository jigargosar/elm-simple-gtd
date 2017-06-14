module WebComponents exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Polymer.Paper
import String.Extra


ironIcon =
    Html.node "iron-icon"


iconA =
    attribute "icon"


icon iconName attributes =
    ironIcon (attributes ++ [ iconA iconName ]) []


paperIconButton =
    Html.node "paper-icon-button"


iconButton iconName attributes =
    paperIconButton (attributes ++ [ iconA iconName ]) []


doneAllIconP =
    iconA "done-all"


iconTextButton iconName text_ clickHandler =
    Polymer.Paper.button [ class "icon-text font-caption", onClickStopPropagation clickHandler ]
        [ icon iconName [ class "big" ]
        , text text_
        ]


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
