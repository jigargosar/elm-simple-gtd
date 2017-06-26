module GroupDoc.EditView exposing (..)

import Entity
import X.Keyboard exposing (onEnter, onKeyDownStopPropagation)
import GroupDoc.EditForm
import Model







import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Html exposing (onClickStopPropagation)
import View.Shared exposing (defaultOkCancelArchiveButtons)


init : GroupDoc.EditForm.Model -> Html Model.Msg
init form =
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
