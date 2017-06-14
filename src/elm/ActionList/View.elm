module ActionList.View exposing (..)

import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.FullBleedCapture
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


init appModel model =
    View.FullBleedCapture.init
        { onMouseDown = Model.OnDeactivateEditingMode
        , children =
            [ div [ class "modal modal-center" ] []
            ]
        }
