module Main.View.AppDrawer exposing (..)

import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.View.AllTodoLists exposing (allGroupedTodoListView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
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
import Todo.View
import ViewState exposing (..)


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
                ([ item [ onClick OnShowTodoList ] [ text "All" ]
                 , hr [] []
                 ]
                    ++ listTypeMenuItems m
                    ++ [ hr [] [] ]
                    ++ [ binItemView m
                       , doneItemView m
                       ]
                )
            ]
        ]


binItemView m =
    item [onClick OnBinClicked] [ text "Bin" ]


doneItemView m =
    item [] [ text "Done" ]


getTodoLists =
    getTodoList >> Todo.groupedTodoLists2


listTypeMenuItems =
    getTodoLists
        >> List.map listTypeMenuItem


listTypeMenuItem ( listType, todoList ) =
    let
        ltName =
            Todo.listTypeToName listType
    in
        item [ class "has-hover-items" ]
            ([ span [ id ltName ] [ text (ltName) ]
             , itemBody [] []
             , badge
                [ classList
                    [ "hidden" => (List.length todoList == 0)
                    , "drawer-list-type-badge" => True
                    ]
                , intProperty "label" (List.length todoList)
                , attribute "for" ltName
                ]
                []
             ]
                ++ addHoverItems listType
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
