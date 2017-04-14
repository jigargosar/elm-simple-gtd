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


appDrawerView contextVMs projectVMs m =
    App.drawer [ attribute "slot" "drawer" ]
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ menu
                [ stringProperty "selected" "0"
                , stringProperty "selectable" "paper-item"
                ]
                (contextItems contextVMs m
                    ++ [ divider ]
                    ++ groupByProjectItem projectVMs m
                    ++ [ divider ]
                    ++ [ binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


divider =
    hr [] []


groupByProjectItem projectVMs m =
    [ item [ onClick (SetView GroupByProjectView) ] [ text "Projects" ]
    , divider
    ]
        ++ (List.map entityItem projectVMs)


contextItems contextVMs m =
    [ item [ onClick (SetView GroupByContextView) ] [ text "Contexts" ]
    , divider
    ]
        ++ (List.map entityItem contextVMs)


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]


entityItem vm =
    item [ class "", onClick vm.navigateToEntityMsg ]
        ([ View.Shared.defaultBadge vm
         , itemBody [] []
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
