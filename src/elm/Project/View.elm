module Project.View exposing (..)

import Ext.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import View.Shared exposing (defaultOkCancelDeleteButtons)


edit form =
    div
        [ class "overlay"
        , onClickStopPropagation Model.OnDeactivateEditingMode
        ]
        [ div [ class "modal fixed-center", onClickStopPropagation Model.NOOP ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.NOOP) ]
                    [ input
                        [ class "auto-focus"
                        , autofocus True
                        , defaultValue (form.name)
                        , onEnter Model.SaveCurrentForm

                        --                                  , onInput vm.onNameChanged
                        ]
                        []
                    , label [ class "active" ] [ text "Name" ]
                    ]
                , defaultOkCancelDeleteButtons {- vm.onDeleteClicked -} Model.NOOP
                ]
            ]
        ]
