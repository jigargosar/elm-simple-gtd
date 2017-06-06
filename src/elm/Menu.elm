module Menu exposing (..)

import Document
import Ext.Keyboard exposing (KeyboardEvent, onKeyDown, onKeyDownStopPropagation)
import Ext.List as List
import Html.Attributes.Extra exposing (intProperty)
import Keyboard.Extra as Key
import Model exposing (Model, commonMsg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Polymer.Paper as Paper
import Project
import Todo


type alias ViewModel item msg =
    { items : List item
    , onSelect : item -> msg
    , itemDomId : item -> String
    , domId : String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    , maybeFocusIndex : Maybe Int
    , onFocusIndexChanged : Int -> msg
    }


type alias ItemViewModel msg =
    { shouldAutoFocus : Bool
    , tabIndexValue : Int
    , isSelected : Bool
    , onClick : msg
    , onKeyDown : KeyboardEvent -> msg
    , view : Html msg
    }


createItemViewModel : ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM index item =
    let
        clampIndex =
            List.clampIndexIn menuVM.items

        selectedIndex =
            menuVM.items |> List.findIndex menuVM.isSelected ?= 0 |> clampIndex

        focusedIndex =
            menuVM.maybeFocusIndex
                ?= selectedIndex
                |> clampIndex
                |> Debug.log "FI"

        isFocused =
            focusedIndex == index

        isSelected =
            selectedIndex == index

        tabIndexValue =
            let
                boolToTabIndexValue bool =
                    if bool then
                        0
                    else
                        -1
            in
                isFocused |> boolToTabIndexValue

        shouldAutoFocus =
            tabIndexValue == 0

        onFocusIndexChange =
            add focusedIndex >> clampIndex >> menuVM.onFocusIndexChanged

        onSelect =
            menuVM.onSelect item

        onKeyDown { key } =
            case key of
                Key.ArrowUp ->
                    onFocusIndexChange -1

                Key.ArrowDown ->
                    onFocusIndexChange 1

                Key.Enter ->
                    onSelect

                _ ->
                    onFocusIndexChange 0
    in
        { isSelected = isSelected
        , shouldAutoFocus = shouldAutoFocus
        , tabIndexValue = tabIndexValue
        , onClick = onSelect
        , view = menuVM.itemView item
        , onKeyDown = onKeyDown
        }


view vm =
    div
        [ class "modal-background"
        , onKeyDownStopPropagation ((\_ -> commonMsg.noOp))
        , onClickStopPropagation Model.DeactivateEditingMode
        ]
        [ div
            [ id vm.domId
            , class "menu"
            , attribute "data-prevent-default-keys" "Tab"
            ]
            (vm.items |> List.indexedMap (createItemViewModel vm >>> menuItem))
        ]


menuItem vm =
    div
        [ onClick vm.onClick
        , tabindex vm.tabIndexValue
        , onKeyDown vm.onKeyDown
        , classList [ "auto-focus" => vm.shouldAutoFocus, "item" => True ]
        ]
        [ vm.view ]
