module View.AppDrawer exposing (..)

import Entity.ViewModel
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
import WebComponents exposing (iconP, onBoolPropertyChanged)


view contextVM projectVM m =
    App.drawer []
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ menu
                [ stringProperty "selected" "0"
                , stringProperty "selectable" "paper-item"
                , stringProperty "selectedAttribute" "selected"
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
        , div [ class "layout horizontal center show-on-hover" ]
            [ toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] []
            , trashIcon
            , iconButton [ iconP "add", onClickStopPropagation Msg.NoOp ] []
            ]
        ]
    , divider
    ]
        ++ (List.map entityItem vmList)


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]



--onPropertyChanged decoder propertyName tagger =


entityItem : Entity.ViewModel.ViewModel -> Html Msg
entityItem vm =
    item [ class "", onBoolPropertyChanged "focused" vm.onActiveStateChanged ]
        ([ itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ settingsButton vm.startEditingMsg ]
