module Entity.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import Polymer.Paper as Paper
import Svg.Events exposing (onFocusIn)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.Shared exposing (defaultOkCancelDeleteButtons, expand)
import WebComponents


initKeyed tabindexAV mainViewModel vm =
    ( vm.id, init tabindexAV mainViewModel.shared vm )


init tabindexAV vc vm =
    if vm.id /= "" then
        vc.getMaybeEditEntityFormForEntityId vm.id
            |> Maybe.unpack (\_ -> defaultView tabindexAV vm) (editEntityView tabindexAV vm)
    else
        defaultView tabindexAV vm


defaultView tabindexAV vm =
    div
        [ class "entity-item"
        , tabindexAV
        , onFocusIn vm.onFocusIn
        , onFocus vm.onFocus
        , onBlur vm.onBlur
        ]
        [ div [ class "layout horizontal justified" ]
            [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
            , WebComponents.iconButton "create"
                [ class "flex-none", onClick vm.startEditingMsg, tabindexAV ]
            ]
        ]


editEntityView tabindexAV vm form =
    div
        [ class "entity-item"
        , tabindexAV
        , onFocusIn vm.onFocusIn
        , onFocus vm.onFocus
        , onBlur vm.onBlur
        ]
        [ div [ class "layout vertical" ]
            [ Paper.input
                [ class "edit-entity-name-input auto-focus"
                , stringProperty "label" "Name"
                , value (form.name)
                , onInput vm.onNameChanged
                , onClickStopPropagation (Msg.FocusPaperInput ".edit-entity-name-input")
                ]
                []
            , defaultOkCancelDeleteButtons vm.onDeleteClicked
            ]
        ]
