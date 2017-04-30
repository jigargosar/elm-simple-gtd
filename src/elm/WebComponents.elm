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


iconP =
    stringProperty "icon"


icon iconName attributes =
    ironIcon (attributes ++ [ iconP iconName ]) []


paperIconButton =
    Html.node "paper-icon-button"


iconButton iconName attributes =
    paperIconButton (attributes ++ [ iconP iconName ]) []


doneAllIconP =
    iconP "done-all"


iconTextButton iconName text_ clickHandler =
    Polymer.Paper.button [ class "icon-text font-caption", onClickStopPropagation clickHandler ]
        [ icon iconName [ class "big" ]
        , text text_
        ]


secondaryA =
    attribute "secondary" "true"


labelA =
    attribute "label"


selectedA =
    attribute "selected"


noLabelFloatP =
    boolProperty "noLabelFloatP" True


onBoolPropertyChanged propertyName tagger =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map tagger (Json.Decode.at [ "detail", "value" ] Json.Decode.bool))


onPropertyChanged propertyName tagger =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map tagger (Json.Decode.at [ "detail", "value" ] Json.Decode.string))


testDialog =
    Polymer.Paper.dialog
        [ boolProperty "opened" True
        , boolProperty "alwaysOnTop" True

        --        , boolProperty "no-cancel-on-outside-click" True
        , stringProperty "verticalAlign" "top"
        , stringProperty "horizontalAlign" "left"
        , style [ "margin" => "0", "position" => "absolute" ]

        --        , class "full-view"
        ]
        [ h2 [] [ text "Big Header" ] ]


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    on "change" (Json.Decode.map tagger targetValue)
