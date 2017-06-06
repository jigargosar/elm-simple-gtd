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


createItemViewModel : ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM index item =
    let
        clampIndex =
            List.clampIndexIn menuVM.items

        selectedIndex =
            menuVM.items |> List.findIndex menuVM.isSelected ?= 0 |> clampIndex

        maybeFocusedIndex key =
            menuVM.items
                |> List.findIndex (menuVM.itemDomId >> equals key)

        focusedIndex =
            menuVM.maybeFocusKey
                ?+> maybeFocusedIndex
                ?= selectedIndex
                |> clampIndex

        onSelect =
            menuVM.onSelect item

        indexToFocusKey index =
            menuVM.items |> List.getAt index ?|> menuVM.itemDomId |> Maybe.orElse menuVM.maybeFocusKey

        onKeyDown { key } =
            let
                onFocusIndexChange =
                    add focusedIndex
                        >> clampIndex
                        >> indexToFocusKey
                        >> menuVM.onFocusIndexChanged
            in
                case key of
                    Key.ArrowUp ->
                        onFocusIndexChange -1

                    Key.ArrowDown ->
                        onFocusIndexChange 1

                    Key.Enter ->
                        onSelect

                    _ ->
                        onFocusIndexChange 0

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


view vm =
    div
        [ class "modal-background"
        , onKeyDownStopPropagation ((\_ -> commonMsg.noOp))
        , onClickStopPropagation Model.DeactivateEditingMode
        ]
        [ ul
            [ id vm.domId
            , class "menu"
            , attribute "data-prevent-default-keys" "Tab"
            ]
            (vm.items |> List.indexedMap (createItemViewModel vm >>> menuItem))
        ]


menuItem vm =
    li
        [ onClick vm.onClick
        , tabindex vm.tabIndexValue
        , onKeyDown vm.onKeyDown
        , classList [ "auto-focus" => vm.shouldAutoFocus ]
        ]
        [ vm.view ]
