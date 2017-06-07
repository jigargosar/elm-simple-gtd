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
import View.FullBleedCapture


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
    , onOutsideMouseDown : msg
    }


type alias ViewModel msg =
    { selectedIndex : Int
    , focusedIndex : Int
    , isFocusedAt : Int -> Bool
    , isSelectedAt : Int -> Bool
    , tabIndexValueAt : Int -> Int
    , onFocusedItemKeyDown : KeyboardEvent -> msg
    , onKeyDownAt : Int -> KeyboardEvent -> msg
    }


createViewModel : Config item msg -> ViewModel msg
createViewModel config =
    let
        clampIndex =
            List.clampIndexIn config.items

        selectedIndex =
            config.items |> List.findIndex config.isSelected ?= 0 |> clampIndex

        focusedIndex =
            findMaybeFocusedIndex config ?= selectedIndex

        isFocusedAt =
            equals focusedIndex

        maybeFocusedItem =
            List.getAt focusedIndex config.items

        onFocusedItemKeyDown { key } =
            let
                moveFocusIndexBy offset =
                    let
                        indexToFocusKey index =
                            List.getAt index config.items ?|> config.itemKey |> Maybe.orElse config.maybeFocusKey
                    in
                        offset
                            |> add focusedIndex
                            >> clampIndex
                            >> indexToFocusKey
            in
                case key of
                    Key.Enter ->
                        maybeFocusedItem ?|> config.onSelect ?= config.noOp

                    Key.ArrowUp ->
                        moveFocusIndexBy -1 |> config.onFocusIndexChanged

                    Key.ArrowDown ->
                        moveFocusIndexBy 1 |> config.onFocusIndexChanged

                    _ ->
                        config.noOp

        onKeyDownAt index =
            if isFocusedAt index then
                onFocusedItemKeyDown
            else
                (\_ -> config.noOp)
    in
        { selectedIndex = selectedIndex
        , focusedIndex = focusedIndex
        , isFocusedAt = isFocusedAt
        , isSelectedAt = equals selectedIndex
        , tabIndexValueAt = isFocusedAt >> boolToTabIndexValue
        , onFocusedItemKeyDown = onFocusedItemKeyDown
        , onKeyDownAt = onKeyDownAt
        }


findMaybeFocusedIndex vm =
    let
        findIndexOfItemWithKey key =
            List.findIndex (vm.itemKey >> equals key) vm.items
    in
        vm.maybeFocusKey ?+> findIndexOfItemWithKey >>? List.clampIndexIn vm.items


view : Config item msg -> Html msg
view config =
    let
        menuVM =
            createViewModel config

        itemViewList =
            config.items
                .#|> createItemViewModel menuVM config
                >>> menuItemView
    in
        View.FullBleedCapture.init
            { onMouseDown = config.onOutsideMouseDown
            , children =
                [ ul
                    [ id config.domId
                    , class "menu"
                    , attribute "data-prevent-default-keys" "Tab"
                    ]
                    itemViewList
                ]
            }


type alias ItemViewModel msg =
    { isFocused : Bool
    , tabIndexValue : Int
    , isSelected : Bool
    , onClick : msg
    , onKeyDown : KeyboardEvent -> msg
    , view : Html msg
    }


createItemViewModel : ViewModel msg -> Config item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM config index item =
    { isSelected = menuVM.isSelectedAt index
    , isFocused = menuVM.isFocusedAt index
    , tabIndexValue = menuVM.tabIndexValueAt index
    , onClick = config.onSelect item
    , view = config.itemView item
    , onKeyDown = menuVM.onKeyDownAt index
    }


boolToTabIndexValue bool =
    if bool then
        0
    else
        -1


menuItemView itemVM =
    li
        [ onClick itemVM.onClick
        , tabindex itemVM.tabIndexValue
        , onKeyDownStopPropagation itemVM.onKeyDown
        , classList [ "auto-focus" => itemVM.isFocused ]
        ]
        [ itemVM.view ]
