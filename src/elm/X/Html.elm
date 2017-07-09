module X.Html exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (..)
import Html.Events exposing (onWithOptions)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E


stopPropagation =
    { stopPropagation = True
    , preventDefault = False
    }


preventDefault =
    { stopPropagation = False
    , preventDefault = True
    }


stopAll =
    { stopPropagation = True
    , preventDefault = True
    }


onStopPropagation eventName =
    onWithOptions eventName stopPropagation


onPreventDefault eventName =
    onWithOptions eventName preventDefault


onStopAll eventName =
    onWithOptions eventName stopAll


onClickStopPropagation =
    D.succeed >> onStopPropagation "click"


onClickPreventDefault =
    D.succeed >> onPreventDefault "click"


onClickStopAll =
    D.succeed >> onStopAll "click"


onMouseDownStopPropagation =
    D.succeed >> onStopPropagation "mousedown"


onFocusIn =
    D.succeed >> Html.Events.on "focusin"


attr =
    attribute


prop =
    stringProperty


stringProperty : String -> String -> Attribute msg
stringProperty name value =
    E.string value |> property name


boolProp =
    boolProperty


boolProperty : String -> Bool -> Attribute msg
boolProperty name value =
    E.bool value |> property name
