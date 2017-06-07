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
    { onSelect : item -> msg
    , itemKey : item -> String
    , domId : String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    , maybeFocusKey : Maybe String
    , onFocusIndexChanged : Maybe String -> msg
    , noOp : msg
    , onOutsideMouseDown : msg
    }


type alias ViewModel item msg =
    { isFocusedAt : Int -> Bool
    , isSelectedAt : Int -> Bool
    , tabIndexValueAt : Int -> Int
    , onKeyDownAt : Int -> KeyboardEvent -> msg
    , onSelect : item -> msg
    , itemView : item -> Html msg
    }


createViewModel : List item -> Config item msg -> ViewModel item msg
createViewModel items config =
    let
        clampIndex =
            List.clampIndexIn items

        selectedIndex =
            items |> List.findIndex config.isSelected ?= 0 |> clampIndex

        focusedIndex =
            findMaybeFocusedIndex items config ?= selectedIndex

        isFocusedAt =
            equals focusedIndex

        maybeFocusedItem =
            List.getAt focusedIndex items

        onFocusedItemKeyDown { key } =
            let
                moveFocusIndexBy offset =
                    let
                        indexToFocusKey index =
                            List.getAt index items ?|> config.itemKey |> Maybe.orElse config.maybeFocusKey
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
        { isFocusedAt = isFocusedAt
        , isSelectedAt = equals selectedIndex
        , tabIndexValueAt = isFocusedAt >> boolToTabIndexValue
        , onKeyDownAt = onKeyDownAt
        , onSelect = config.onSelect
        , itemView = config.itemView
        }


findMaybeFocusedIndex items config =
    let
        findIndexOfItemWithKey key =
            List.findIndex (config.itemKey >> equals key) items
    in
        config.maybeFocusKey ?+> findIndexOfItemWithKey >>? List.clampIndexIn items


view : List item -> Config item msg -> Html msg
view items config =
    let
        menuVM =
            createViewModel items config

        itemViewList =
            items
                .#|> createItemViewModel menuVM
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


createItemViewModel : ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM index item =
    { isSelected = menuVM.isSelectedAt index
    , isFocused = menuVM.isFocusedAt index
    , tabIndexValue = menuVM.tabIndexValueAt index
    , onClick = menuVM.onSelect item
    , view = menuVM.itemView item
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
