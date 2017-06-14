module Menu exposing (..)

import Char
import Document
import Ext.Keyboard exposing (KeyboardEvent, onKeyDown, onKeyDownStopPropagation)
import Ext.List as List
import Html.Attributes.Extra exposing (intProperty)
import Html.Keyed
import Keyboard.Extra as Key
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
import Project
import Todo
import Tuple2
import View.FullBleedCapture


type alias State =
    { maybeFocusKey : Maybe String
    }


initState : State
initState =
    { maybeFocusKey = Nothing
    }


setFocusKey focusKey state =
    { state | maybeFocusKey = Just focusKey }


setFocusKeyIn =
    flip setFocusKey


type alias Config item msg =
    { onSelect : item -> msg
    , itemKey : item -> String
    , itemSearchText : item -> String
    , itemView : item -> Html msg
    , isSelected : item -> Bool
    , onStateChanged : State -> msg
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
    , itemKey : item -> String
    }


splitSwapListAt : Int -> List item -> List item
splitSwapListAt index =
    List.splitAt index >> Tuple2.swap >> uncurry List.append


createViewModel : List item -> State -> Config item msg -> ViewModel item msg
createViewModel items state config =
    let
        clampIndex =
            List.clampIndexIn items

        maybeSelectedIndex =
            items |> List.findIndex config.isSelected ?|> clampIndex

        maybeFocusedIndex =
            let
                findIndexOfItemWithKey key =
                    List.findIndex (config.itemKey >> equals key) items
            in
                state.maybeFocusKey ?+> findIndexOfItemWithKey >>? List.clampIndexIn items

        focusedIndex =
            maybeFocusedIndex |> Maybe.orElse maybeSelectedIndex ?= 0

        stateChangedMsgFromMaybeFocusedItem maybeItem =
            maybeItem
                ?|> config.itemKey
                >> setFocusKeyIn state
                >> config.onStateChanged
                ?= config.noOp

        onFocusItemStartingWithMsg singleChar =
            let
                findPred =
                    let
                        boil =
                            String.toLower

                        charString =
                            String.fromChar singleChar
                    in
                        config.itemSearchText >> boil >> String.startsWith (boil charString)
            in
                items
                    |> splitSwapListAt (focusedIndex + 1)
                    |> List.find findPred
                    |> stateChangedMsgFromMaybeFocusedItem

        onFocusedItemKeyDown { key, keyString } =
            let
                onFocusIndexChangeByMsg offset =
                    focusedIndex
                        + offset
                        |> clampIndex
                        |> (List.getAt # items)
                        |> stateChangedMsgFromMaybeFocusedItem
            in
                case key of
                    Key.Enter ->
                        List.getAt focusedIndex items ?|> config.onSelect ?= config.noOp

                    Key.ArrowUp ->
                        onFocusIndexChangeByMsg -1

                    Key.ArrowDown ->
                        onFocusIndexChangeByMsg 1

                    _ ->
                        case keyString |> String.toList of
                            singleChar :: [] ->
                                onFocusItemStartingWithMsg singleChar

                            _ ->
                                config.noOp

        isFocusedAt =
            equals focusedIndex

        onKeyDownAt index =
            if isFocusedAt index then
                onFocusedItemKeyDown
            else
                (\_ -> config.noOp)
    in
        { isFocusedAt = isFocusedAt
        , isSelectedAt = maybeSelectedIndex ?|> equals ?= (\_ -> False)
        , tabIndexValueAt = isFocusedAt >> boolToTabIndexValue
        , onKeyDownAt = onKeyDownAt
        , onSelect = config.onSelect
        , itemView = config.itemView
        , itemKey = config.itemKey
        }


view : List item -> State -> Config item msg -> Html msg
view items state config =
    let
        menuVM =
            createViewModel items state config

        itemViewList =
            items
                .#|> createItemViewModel menuVM
                >>> menuItemView
    in
        View.FullBleedCapture.init
            { onMouseDown = config.onOutsideMouseDown
            , children =
                [ Html.Keyed.node "ul"
                    [ id "popup-menu"
                    , class "collection z-depth-4"
                    , attribute "data-prevent-default-keys" "Tab"
                    ]
                    itemViewList
                ]
            }


type alias ItemViewModel msg =
    { key : String
    , isFocused : Bool
    , tabIndexValue : Int
    , isSelected : Bool
    , onClick : msg
    , onKeyDown : KeyboardEvent -> msg
    , view : Html msg
    }


createItemViewModel : ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM index item =
    { key = menuVM.itemKey item
    , isSelected = menuVM.isSelectedAt index
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
    ( itemVM.key
    , li
        [ onClick itemVM.onClick
        , tabindex itemVM.tabIndexValue
        , onKeyDownStopPropagation itemVM.onKeyDown
        , classList
            [ "auto-focus" => itemVM.isFocused
            , "collection-item" => True
            , "active" => itemVM.isSelected
            ]
        ]
        [ itemVM.view ]
    )
