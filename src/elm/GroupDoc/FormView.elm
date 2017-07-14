module GroupDoc.FormView exposing (..)

import Entity.Types exposing (EntityId(..))
import GroupDoc.FormTypes exposing (GroupDocForm, GroupDocFormMode(..))
import GroupDoc.Types exposing (GroupDocType(..))
import Msg
import Tuple2
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Model
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import View.Shared exposing (..)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import X.Function exposing (..)


init : GroupDocForm -> Html Msg.AppMsg
init form =
    let
        ( entityId, nameLabel ) =
            (case form.groupDocType of
                ContextGroupDoc ->
                    ( ContextId, "Context" )

                ProjectGroupDoc ->
                    ( ProjectId, "Project" )
            )
                |> Tuple2.mapEach (apply form.id) (String.append # " Name")

        toMsg =
            Msg.onEntityUpdateMsg entityId

        fireNameChanged =
            Entity.Types.EUA_SetFormText >> toMsg

        fireSaveForm =
            Msg.OnSaveExclusiveModeForm

        fireCancel =
            Msg.OnDeactivateEditingMode

        fireToggleArchive =
            toMsg Entity.Types.EUA_ToggleArchived

        defaultButtons =
            case form.mode of
                GDFM_Edit ->
                    defaultOkCancelArchiveButtons form.isArchived fireToggleArchive

                GDFM_Add ->
                    defaultOkCancelButtons
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
                        , label [ class "active" ] [ text nameLabel ]
                        ]
                    , defaultButtons
                    ]
                ]
            ]
