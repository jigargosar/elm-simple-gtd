module Main.View exposing (appView)

import ActiveTask exposing (MaybeTask)
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import KeyboardExtra as KeyboardExtra exposing (onEscape, onKeyUp)
import Main.Types exposing (EditMode(..), MainViewType(..))
import Main.View.AllTodoLists exposing (..)
import Main.View.AppDrawer exposing (appDrawerView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Time exposing (Time)
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


appView m =
    div []
        [ appDrawerLayoutView m
        , addTodoFabView m
        ]


appDrawerLayoutView m =
    App.drawerLayout []
        [ appDrawerView m
        , App.headerLayout []
            [ appHeaderView m
            , appMainView m
            ]
        ]


appHeaderView m =
    App.header
        [ attribute "reveals" "true"
        , attribute "fixed" "true"
        , attribute "condenses" "true"
        , attribute "effects" "waterfall"
        , attribute "slot" "header"
        ]
        [ App.toolbar
            []
            [ iconButton [ icon "menu", attribute "drawer-toggle" "true" ] []
            , newTodoInputView (getEditMode m)
            ]
        , activeTaskAppToolBarView m
        ]


activeTaskAppToolBarView : Model -> Html Msg
activeTaskAppToolBarView m =
    case getActiveTaskViewModel m of
        Just taskVm ->
            activeTaskView taskVm m

        Nothing ->
            App.toolbar [ class "hidden" ] []


activeTaskView : ActiveTaskViewModel -> Model -> Html Msg
activeTaskView { todoVM, elapsedTime } m =
    App.toolbar []
        [ div [] [ text (todoVM.text ++ " - " ++ (toHHMMSS elapsedTime)) ]
        ]


toHHMMSS : Time -> String
toHHMMSS time =
    let
        roundToFloat =
            round >> toFloat

        roundToString =
            round >> toString

        secondsMilli =
            time / Time.second |> roundToFloat |> (*) Time.second

        minutesMilli =
            time / Time.minute |> roundToFloat |> (*) Time.minute

        hoursMilli =
            time / Time.hour |> roundToFloat |> (*) Time.hour

        seconds =
            abs (secondsMilli - minutesMilli) / Time.second |> roundToString

        --        seconds =
        --            rem (round time) (round Time.second) |> toString
        minutes =
            abs (minutesMilli - hoursMilli) / Time.minute |> roundToString

        hours =
            (hoursMilli) / Time.hour |> roundToString
    in
        [ hours, minutes, seconds ] |> String.join ":"


toHHMMSS2 : Time -> String
toHHMMSS2 time =
    let
        elapsedMilli =
            round time

        millis =
            elapsedMilli % 1000

        seconds =
            (elapsedMilli - millis) % (1000 * 60)

        minutes =
            (elapsedMilli - seconds - millis) % (1000 * 60 * 60)

        hours =
            (elapsedMilli - minutes - seconds - millis) // 60

        res : List Int
        res =
            [ hours, minutes, seconds, millis ]
    in
        res .|> toString |> String.join ":"


appMainView m =
    div [ id "main-view" ]
        [ case getMainViewType m of
            AllByGroupView ->
                allTodoListByGroupView m

            BinView ->
                todoListView m

            DoneView ->
                todoListView m

            _ ->
                allTodoListByGroupView m
        ]


newTodoInputId =
    "new-todo-input"


newTodoInputView editMode =
    case editMode of
        EditNewTodoMode text ->
            input
                [ id newTodoInputId
                , onInput onNewTodo.input
                , value text
                , onBlur onNewTodo.blur
                , onKeyUp (onNewTodo.keyUp text)
                , autofocus True
                ]
                []

        _ ->
            span [] []


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick (onNewTodo.add newTodoInputId)
        ]
        []


type alias TodoViewModel =
    Todo
