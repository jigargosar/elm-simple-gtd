module GroupDoc.FormView exposing (..)

import Entity.Types exposing (EntityId(..))
import GroupDoc.Types exposing (GroupDocForm, GroupDocFormMode(..))
import GroupDoc.Types exposing (GroupDocType(..))
import Mat
import Tuple2
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


--init : GroupDocForm -> Html Msg.AppMsg


init config form =
    let
        ( entityId, nameLabel ) =
            (case form.groupDocType of
                ContextGroupDocType ->
                    ( ContextId, "Context" )

                ProjectGroupDocType ->
                    ( ProjectId, "Project" )
            )
                |> Tuple2.mapEach (apply form.id) (String.append # " Name")

        toMsg =
            config.onEntityUpdateMsg entityId

        fireNameChanged =
            config.onGD_UpdateFormName form

        fireSaveForm =
            config.onSaveExclusiveModeForm

        fireCancel =
            config.revertExclusiveMode

        fireToggleArchive =
            config.onToggleGroupDocArchived form.groupDocId

        defaultButtons =
            case form.mode of
                GDFM_Edit ->
                    Mat.okCancelArchiveButtons config form.isArchived fireToggleArchive

                GDFM_Add ->
                    Mat.okCancelButtons config
    in
        div
            [ class "overlay"
            , onClickStopPropagation fireCancel
            , onKeyDownStopPropagation (\_ -> config.noop)
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation config.noop ]
                [ div [ class "modal-content" ]
                    [ div
                        [ class "input-field"
                        , onKeyDownStopPropagation (\_ -> config.noop)
                        , onClickStopPropagation config.noop
                        ]
                        [ input
                            [ class "auto-focus"
                            , autofocus True
                            , defaultValue (form.name)
                            , onEnter fireSaveForm
                            , onInput fireNameChanged
                            , placeholder "E.g. Trip Planning, Home Decoration"
                            ]
                            []
                        , label [ class "active" ] [ text nameLabel ]
                        ]
                    , defaultButtons
                    ]
                ]
            ]
