module View.AppDrawer exposing (..)

import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, tabindex, value)
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
import View.Shared


appDrawerView contextVM projectVM m =
    App.drawer [ attribute "slot" "drawer" ]
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ menu
                [ stringProperty "selected" "0"
                , stringProperty "selectable" "paper-item"
                ]
                (groupByEntity contextVM
                    ++ [ divider ]
                    ++ groupByEntity projectVM
                    ++ [ divider ]
                    ++ [ binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


divider =
    hr [] []


groupByEntity { vmList, viewType, title } =
    [ item [ onClick (SetView viewType) ]
        [ itemBody [] [ span [ class "ellipsis" ] [ text title ] ]
        , toggleButton [] []
        ]
    , divider
    ]
        ++ (List.map entityItem vmList)


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]


entityItem vm =
    item [ class "", onClick vm.navigateToEntityMsg ]
        ([ itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ iconButton
            [ onClick vm.startEditingMsg
            , icon "settings"
            ]
            []
        ]
