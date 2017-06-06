module Menu exposing (..)

import Document
import Ext.Keyboard exposing (onKeyDownStopPropagation)
import Html.Attributes.Extra exposing (intProperty)
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
    , view : Html msg
    }


isIndexSelected vm =
    vm.items |> List.findIndex vm.isSelected ?= 0 |> equals


createItemViewModel : ViewModel item msg -> Int -> item -> ItemViewModel msg
createItemViewModel menuVM index item =
    let
        shouldAutoFocus =
            tabIndexValue == 0

        tabIndexValue =
            let
                boolToTabIndexValue bool =
                    if bool then
                        0
                    else
                        -1
            in
                menuVM.maybeFocusIndex ?|> equals index ?= isSelected |> boolToTabIndexValue

        isSelected =
            index |> isIndexSelected menuVM
    in
        { isSelected = isSelected
        , shouldAutoFocus = shouldAutoFocus
        , tabIndexValue = tabIndexValue
        , onClick = menuVM.onSelect item
        , view = menuVM.itemView item
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
        , classList [ "auto-focus" => vm.shouldAutoFocus, "item" => True ]
        ]
        [ vm.view ]
