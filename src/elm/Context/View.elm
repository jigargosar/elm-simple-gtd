module Context.View exposing (..)

import Entity
import Ext.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Model
import Context
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
    let
        toMsg =
            Model.OnEntityAction form.entity

        fireToggleDelete =
            if Context.isNullId form.id then
                Model.NOOP
            else
                toMsg Entity.ToggleDeleted

        fireNameChanged =
            Entity.NameChanged >> toMsg

        fireSaveForm =
            Model.OnSaveCurrentForm

        fireCancel =
            Model.OnDeactivateEditingMode
    in
        div
            [ class "overlay"
            , onClickStopPropagation Model.OnDeactivateEditingMode
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation fireCancel ]
                [ div [ class "modal-content" ]
                    [ div
                        [ class "input-field"
                        , onKeyDownStopPropagation (\_ -> Model.NOOP)
                        , onClickStopPropagation Model.NOOP
                        ]
                        [ input
                            [ class "auto-focus"
                            , autofocus True
                            , defaultValue (form.name)
                            , onEnter fireSaveForm
                            , onInput fireNameChanged
                            ]
                            []
                        , label [ class "active" ] [ text "Context Name" ]
                        ]
                    , defaultOkCancelDeleteButtons fireToggleDelete
                    ]
                ]
            ]
