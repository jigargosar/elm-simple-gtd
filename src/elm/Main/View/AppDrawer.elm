module Main.View.AppDrawer exposing (..)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.Types exposing (ViewType(..))
import Main.View.AllTodoLists exposing (allTodoListByGroupView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import TodoGroupViewModel exposing (getTodoGroupsViewModel)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import DebugExtra.Debug exposing (tapLog)
import DecodeExtra exposing (traceDecoder)
import Flow
import Json.Decode
import Json.Encode
import List.Extra as List
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Todo exposing (Todo, TodoId)
import Flow.Model as Flow exposing (Node)
import Polymer.Paper exposing (..)
import Polymer.App as App
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Todo.View


appDrawerView m =
    App.drawer [ attribute "slot" "drawer" ]
        [ div
            [ style [ "height" => "100%", "overflow" => "scroll" ]
            ]
            [ {- App.toolbar [] [ text "Simple GTD" ]
                 ,
              -}
              menu
                [ stringProperty "selected" "0"
                ]
                ([ item [ onClick (SetView AllByGroupView) ] [ text "All" ]
                 , hr [] []
                 ]
                    ++ todoGroupsMenuItems m
                    ++ [ hr [] [] ]
                    ++ [ binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


binItemView m =
    item [ onClick (SetView BinView) ] [ text "Bin" ]


doneItemView m =
    item [ onClick (SetView DoneView) ] [ text "Done" ]


todoGroupsMenuItems =
    getTodoGroupsViewModel
        >> List.map listTypeMenuItem


listTypeMenuItem vm =
    let
        badgeForId =
            "id-for-badge-" ++ vm.name
    in
        item [ class "has-hover-items" ]
            ([ span [ id badgeForId ] [ text (vm.name) ]
             , itemBody [] []
             , badge
                [ classList
                    [ "hidden" => (vm.isEmpty)
                    , "drawer-list-type-badge" => True
                    ]
                , intProperty "label" (vm.count)
                , attribute "for" badgeForId
                ]
                []
             ]
                ++ addHoverItems vm.group
            )


addHoverItems listType =
    case listType of
        --        Inbox ->
        --            [ iconButton
        --                [ class "hover-items"
        --                , icon "vaadin-icons:start-cog"
        --                , onClick ProcessInbox
        --                ]
        --                []
        --            ]
        _ ->
            []
