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


type alias Config item msg =
    { items : List item
    , onSelect : item -> msg
    , itemKey : item -> String
    , domId : String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    , maybeFocusKey : Maybe String
    , onFocusIndexChanged : Maybe String -> msg
    , noOp : msg
    , onOutsideClick : msg
    }


type alias ItemViewModel msg =
    { shouldAutoFocus : Bool
    , tabIndexValue : Int
    , isSelected : Bool
    , onClick : msg
    , onKeyDown : KeyboardEvent -> msg
    , view : Html msg
    }


boolToTabIndexValue bool =
    if bool then
        0
    else
        -1


findMaybeFocusedIndex vm =
    let
        findIndexOfItemWithKey key =
            List.findIndex (vm.itemKey >> equals key) vm.items
    in
        vm.maybeFocusKey ?+> findIndexOfItemWithKey >>? List.clampIndexIn vm.items


createItemViewModel : Int -> Int -> Config item msg -> Int -> item -> ItemViewModel msg
createItemViewModel selectedIndex focusedIndex config index item =
    let
        clampIndex =
            List.clampIndexIn config.items

        onSelect =
            config.onSelect item

        onKeyDown { key } =
            case key of
                Key.Enter ->
                    onSelect

                _ ->
                    config.noOp

        isFocused =
            focusedIndex == index
    in
        { isSelected = selectedIndex == index
        , shouldAutoFocus = isFocused
        , tabIndexValue = boolToTabIndexValue isFocused
        , onClick = onSelect
        , view = config.itemView item
        , onKeyDown = onKeyDown
        }


view : Config item msg -> Html msg
view vm =
    let
        clampIndex =
            List.clampIndexIn vm.items

        selectedIndex =
            vm.items |> List.findIndex vm.isSelected ?= 0 |> clampIndex

        focusedIndex =
            findMaybeFocusedIndex vm ?= selectedIndex

        onKeyDown { key } =
            let
                indexToFocusKey index =
                    List.getAt index vm.items ?|> vm.itemKey |> Maybe.orElse vm.maybeFocusKey

                onFocusIndexChange =
                    add focusedIndex
                        >> clampIndex
                        >> indexToFocusKey
                        >> vm.onFocusIndexChanged
            in
                case key of
                    Key.ArrowUp ->
                        onFocusIndexChange -1

                    Key.ArrowDown ->
                        onFocusIndexChange 1

                    _ ->
                        vm.noOp

        itemViewList =
            vm.items
                .#|> createItemViewModel selectedIndex focusedIndex vm
                >>> menuItem
    in
        div
            [ class "modal-background"
            , onClickStopPropagation vm.onOutsideClick
            ]
            [ ul
                [ id vm.domId
                , class "menu"
                , attribute "data-prevent-default-keys" "Tab"
                , onKeyDownStopPropagation onKeyDown
                ]
                itemViewList
            ]


menuItem vm =
    li
        [ onClick vm.onClick
        , tabindex vm.tabIndexValue
        , onKeyDown vm.onKeyDown
        , classList [ "auto-focus" => vm.shouldAutoFocus ]
        ]
        [ vm.view ]
