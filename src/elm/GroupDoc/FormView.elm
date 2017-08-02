module GroupDoc.FormView exposing (..)

import Entity exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import Toolkit.Operators exposing (..)
import Tuple2
import Types.GroupDoc exposing (..)
import X.Function exposing (..)
import X.Html exposing (onClickStopPropagation)
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)


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

        fireNameChanged =
            config.updateGroupDocFromNameMsg form

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
                        , defaultValue form.name
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
