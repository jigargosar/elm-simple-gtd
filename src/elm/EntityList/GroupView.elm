module EntityList.GroupView exposing (..)

import Ext.Keyboard exposing (onKeyDown, onKeyDownStopPropagation)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation, onEnter)
import Model
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
        tabindexAV =
            vm.tabindexAV
    in
        div
            [ tabindexAV
            , onFocusIn vm.onFocusIn
            , onKeyDown vm.onKeyDownMsg
            , classList [ "entity-item focusable-list-item" => True ]
            ]
            (defaultView tabindexAV vm)


defaultView tabindexAV vm =
    let
        editButton =
            if vm.isEditable then
                WebComponents.iconButton "create"
                    [ class "flex-none", onClick vm.startEditingMsg, tabindexAV ]
            else
                span [] []
    in
        [ div [ class "layout horizontal justified" ]
            [ div [ class "title font-nowrap flex-auto" ] [ View.Shared.defaultBadge vm ]
            , editButton
            ]
        ]
