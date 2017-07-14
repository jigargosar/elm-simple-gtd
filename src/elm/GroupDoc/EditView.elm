module GroupDoc.EditView exposing (..)

import Entity.Types exposing (EntityId(..))
import GroupDoc.FormTypes exposing (GroupDocEditForm)
import GroupDoc.Types exposing (GroupDocType(..))
import Msg
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Model
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import View.Shared exposing (defaultOkCancelArchiveButtons)


init : GroupDocEditForm -> Html Msg.AppMsg
init form =
    let
        entityId =
            form.id
                |> case form.groupDocType of
                    ContextGroupDoc ->
                        ContextId

                    ProjectGroupDoc ->
                        ProjectId

        toMsg =
            Msg.onEntityUpdateMsg entityId

        fireNameChanged =
            Entity.Types.EUA_SetFormText >> toMsg

        fireSaveForm =
            Msg.OnSaveCurrentForm

        fireCancel =
            Msg.OnDeactivateEditingMode

        fireToggleArchive =
            toMsg Entity.Types.EUA_ToggleArchived
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
