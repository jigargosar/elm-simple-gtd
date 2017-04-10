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
import View.TodoList exposing (groupByContextView)
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
import View.Context


appDrawerView contextVMs projectVMs m =
    App.drawer [ attribute "slot" "drawer" ]
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ menu
                [ stringProperty "selected" "0"
                ]
                ([ item [ onClick (SetView GroupByContextView) ] [ text "Contexts" ]
                 , divider
                 ]
                    ++ List.map contextItem contextVMs
                    ++ [ divider
                       , projectsItemView m
                       , divider
                       ]
                    ++ List.map projectItem projectVMs
                    ++ [ divider
                       , binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


divider =
    hr [] []


projectsItemView m =
    item [ onClick (SetView ProjectListView) ] [ text "Projects" ]


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]


contextItem vm =
    let
        idForBadge =
            "app-drawer-id-for-badge-context-" ++ (vm.id)
    in
        item [ class "has-hover-items", onClickStopPropagation (Msg.SetView (ContextView vm.id)) ]
            ([ span [ id idForBadge ] [ text (vm.name) ]
             , itemBody [] []
             , badge
                [ classList
                    [ "hidden" => (vm.isEmpty)
                    , "drawer-list-type-badge" => True
                    ]
                , intProperty "label" (vm.count)
                , attribute "for" idForBadge
                ]
                []
             , hoverIcons vm
             ]
            )


hoverIcons vm =
    --    let
    --        children =
    --            if vm.isEditable then
    --                [ editIconButton vm
    --                , deleteIconButton vm
    --                ]
    --            else
    --                []
    --    in
    div [ class "hover-items" ]
        [ iconButton
            [ onClick Msg.NoOp
            , icon "settings"
            ]
            []
        ]


deleteIconButton vm =
    iconButton
        [ onClick vm.onDeleteClicked
        , icon "delete"
        ]
        []


editIconButton vm =
    iconButton
        [ onClick vm.onEditClicked
        , icon "create"
        ]
        []


projectItem vm =
    let
        idForBadge =
            "app-drawer-id-for-badge-project-" ++ (String.Extra.dasherize vm.id)
    in
        item [ class "has-hover-items", onClickStopPropagation (Msg.SetView (ProjectView vm.id)) ]
            ([ span [ id idForBadge ] [ text (vm.name) ]
             , itemBody [] []
             , badge
                [ classList
                    [ "hidden" => (vm.isEmpty)
                    , "drawer-list-type-badge" => True
                    ]
                , intProperty "label" (vm.count)
                , attribute "for" idForBadge
                ]
                []
             , hoverIcons vm
             ]
            )
