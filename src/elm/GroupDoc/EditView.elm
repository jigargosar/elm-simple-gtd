module GroupDoc.EditView exposing (..)

import Entity.Types
import GroupDoc.FormTypes exposing (GroupDocEditForm)
import Msg
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Model
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import View.Shared exposing (defaultOkCancelArchiveButtons)


init : GroupDocEditForm -> Html Msg.Msg
init form =
    let
        toMsg =
            Msg.onEntityUpdateMsg form.entity

        fireNameChanged =
            Entity.Types.OnEntityTextChanged >> toMsg

        fireSaveForm =
            Msg.OnSaveCurrentForm

        fireCancel =
            Msg.OnDeactivateEditingMode

        fireToggleArchive =
            toMsg Entity.Types.OnEntityToggleArchived
    in
        div
            [ class "overlay"
            , onClickStopPropagation fireCancel
            , onKeyDownStopPropagation (\_ -> Model.noop)
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation Model.noop ]
                [ div [ class "modal-content" ]
                    [ div
                        [ class "input-field"
                        , onKeyDownStopPropagation (\_ -> Model.noop)
                        , onClickStopPropagation Model.noop
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
