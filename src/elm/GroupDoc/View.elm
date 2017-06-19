module GroupDoc.View exposing (..)

import Entity
import Ext.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import GroupDoc.EditForm
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
import View.Shared exposing (defaultOkCancelArchiveButtons)


edit : GroupDoc.EditForm.Model -> Html Model.Msg
edit form =
    let
        toMsg =
            Model.OnEntityAction form.entity

        fireNameChanged =
            Entity.NameChanged >> toMsg

        fireSaveForm =
            Model.OnSaveCurrentForm

        fireCancel =
            Model.OnDeactivateEditingMode

        fireToggleArchive =
            toMsg Entity.ToggleArchived
    in
        div
            [ class "overlay"
            , onClickStopPropagation fireCancel
            , onKeyDownStopPropagation (\_ -> Model.NOOP)
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation Model.NOOP ]
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
                        , label [ class "active" ] [ text form.nameLabel ]
                        ]
                    , defaultOkCancelArchiveButtons form.isArchived fireToggleArchive
                    ]
                ]
            ]
