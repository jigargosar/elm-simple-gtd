module Main.View.DrawerMenu exposing (..)

import Html exposing (hr, span, text)
import Html.Attributes.Extra exposing (intProperty)
import Main.Msg exposing (Msg(OnShowTodoList))
import Polymer.Attributes exposing (icon, stringProperty)
import Polymer.Paper exposing (badge, iconButton, item, itemBody, menu)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Main.Model exposing (getTodoList)
import Todo exposing (TodoGroup(Inbox))


appDrawerMenuView m =
    menu
        [ stringProperty "selected" "0"
        ]
        ([ item [ onClick OnShowTodoList ] [ text "All" ]
         , hr [] []
         ]
            ++ listTypeMenuItems m
        )


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
