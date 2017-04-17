module View.AppDrawer exposing (..)

import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model.TodoStore
import Msg exposing (Msg(SetView))
import String.Extra
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model exposing (..)
import Todo
import Polymer.Paper exposing (..)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Model.Types exposing (..)
import View.Shared exposing (..)


view contextVM projectVM m =
    App.drawer [ attribute "slot" "drawer" ]
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ menu
                [ stringProperty "selected" "0"
                , stringProperty "selectable" "paper-item"
                ]
                (entityList contextVM
                    ++ [ divider ]
                    ++ entityList projectVM
                    ++ [ divider ]
                    ++ [ binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


divider =
    hr [] []


entityList { vmList, viewType, title, showDeleted } =
    [ item [ onClick (SetView viewType) ]
        [ itemBody [] [ span [ class "ellipsis" ] [ text title ] ]
        , showOnHover [ trashIcon, toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] [] ]
        ]
    , divider
    ]
        ++ (List.map entityItem vmList)


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]


decodeBoolPropertyChange =
    Json.Decode.at [ "detail", "value" ] Json.Decode.bool


onBoolPropertyChanged propertyName handler =
    on ((String.Extra.dasherize propertyName) ++ "-changed")
        (Json.Decode.map handler decodeBoolPropertyChange)


foo vm =
    let
        listener bool =
            if bool then
                vm.onActiveStateChanged
            else
                Msg.NoOp
    in
        on "focused-changed" (Json.Decode.map listener decodeBoolPropertyChange)


entityItem vm =
    item [ class "", foo vm ]
        ([ itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ settingsButton vm.startEditingMsg ]
