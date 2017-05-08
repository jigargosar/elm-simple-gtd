module Entity.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.Shared exposing (expand)
import WebComponents


initKeyed tabindexAV vc vm =
    ( vm.id, init tabindexAV vc vm )


init tabindexAV vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView tabindexAV vm) (editEntityView tabindexAV vm)
    else
        defaultView tabindexAV vm


defaultView tabindexAV vm =
    div
        [ class "entity-item layout horizontal justified width--100"
        , tabindexAV
        ]
        [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
        , WebComponents.iconButton "create"
            [ class "flex-none", onClick vm.startEditingMsg, tabindexAV ]
        ]


editEntityView tabindexAV vm form =
    div
        [ class "entity-item layout vertical"
        , tabindexAV
        ]
        [ input
            [ class "edit-entity-name-input auto-focus"
            , stringProperty "label" "Name"
            , value (form.name)
            , onInput vm.onNameChanged
            , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")

            --                        , onKeyUp vm.onKeyUp
            ]
            []
        , div [ class "layout horizontal" ]
            [ button [ onClick vm.onSaveClicked ] [ "Save" |> text ]
            , button [ onClick vm.onCancelClicked ] [ "Cancel" |> text ]
            , expand []
            , WebComponents.iconButton "delete" [ onClick Msg.SelectionTrashClicked ]
            ]
        ]
