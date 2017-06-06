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
    , itemKey : item -> String
    , domId : String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    , maybeFocusKey : Maybe String
    , onFocusIndexChanged : Maybe String -> msg
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


createItemViewModel : msg -> Int -> Int -> ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel noOp selectedIndex focusedIndex menuVM index item =
    let
        clampIndex =
            List.clampIndexIn menuVM.items

        onSelect =
            menuVM.onSelect item

        onKeyDown { key } =
            case key of
                Key.Enter ->
                    onSelect

                _ ->
                    noOp

        isFocused =
            focusedIndex == index
    in
        { isSelected = selectedIndex == index
        , shouldAutoFocus = isFocused
        , tabIndexValue = boolToTabIndexValue isFocused
        , onClick = onSelect
        , view = menuVM.itemView item
        , onKeyDown = onKeyDown
        }


view : ViewModel item Model.Msg -> Html Model.Msg
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
                        onFocusIndexChange 0
    in
        div
            [ class "modal-background"
            , onKeyDownStopPropagation onKeyDown
            , onClickStopPropagation Model.DeactivateEditingMode
            ]
            [ ul
                [ id vm.domId
                , class "menu"
                , attribute "data-prevent-default-keys" "Tab"
                ]
                (vm.items
                    .#|>
                        (createItemViewModel commonMsg.noOp selectedIndex focusedIndex vm
                            >>> menuItem
                        )
                )
            ]


(.#|>) =
    flip List.indexedMap
infixl 0 .#|>


menuItem vm =
    li
        [ onClick vm.onClick
        , tabindex vm.tabIndexValue
        , onKeyDown vm.onKeyDown
        , classList [ "auto-focus" => vm.shouldAutoFocus ]
        ]
        [ vm.view ]
