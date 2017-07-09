module WebComponents exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode
import String.Extra


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
