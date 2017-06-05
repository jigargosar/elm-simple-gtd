module EntityList.GroupView exposing (..)

import Ext.Keyboard exposing (onKeyDown)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import Model
import Polymer.Paper as Paper
import Svg.Events exposing (onFocusIn)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import View.Shared exposing (defaultOkCancelDeleteButtons)
import WebComponents


initKeyed mainViewModel vm =
    ( vm.id, init mainViewModel.shared vm )


init vc vm =
    let
        maybeForm =
            if vm.id /= "" then
                vc.getMaybeEditEntityFormForEntityId vm.id
            else
                Nothing

        tabindexAV =
            vm.tabindexAV
    in
        div
            [ class "entity-item"
            , tabindexAV
            , onFocusIn vm.onFocusIn
            , onFocus vm.onFocus
            , onBlur vm.onBlur
            , onKeyDown vm.onKeyDownMsg
            ]
            (maybeForm
                |> Maybe.unpack (\_ -> defaultView tabindexAV vm) (editEntityView tabindexAV vm)
            )


defaultView tabindexAV vm =
    [ div [ class "layout horizontal justified" ]
        [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
        , WebComponents.iconButton "create"
            [ class "flex-none", onClick vm.startEditingMsg, tabindexAV ]
        ]
    ]


editEntityView tabindexAV vm form =
    [ div [ class "layout vertical" ]
        [ Paper.input
            [ class "auto-focus"
            , stringProperty "label" "Name"
            , value (form.name)
            , onEnter Model.SaveCurrentForm
            , onInput vm.onNameChanged
            ]
            []
        , defaultOkCancelDeleteButtons vm.onDeleteClicked
        ]
    ]
