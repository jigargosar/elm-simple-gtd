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
        maybeForm =
            if vm.id /= "" then
                vc.getMaybeEditEntityFormForEntityId vm.id
            else
                Nothing

        isEditing =
            maybeForm |> Maybe.isJust

        tabindexAV =
            vm.tabindexAV
    in
        div
            [ tabindexAV
            , onFocusIn vm.onFocusIn
            , onKeyDown vm.onKeyDownMsg
            , classList [ "edit z-depth-2" => isEditing, "entity-item focusable-list-item" => True ]
            ]
            {- (maybeForm
                   |> Maybe.unpack (\_ -> defaultView tabindexAV vm) (editEntityView tabindexAV vm)
               )
            -}
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


editEntityView tabindexAV vm form =
    [ div [ class "static layout vertical" ]
        [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Model.NOOP) ]
            [ input
                [ class "auto-focus"
                , autofocus True
                , defaultValue (form.name)
                , onEnter Model.OnSaveCurrentForm
                , onInput vm.onNameChanged
                ]
                []
            , label [ class "active" ] [ text "Name" ]
            ]
        , defaultOkCancelDeleteButtons vm.onDeleteClicked
        ]
    ]
