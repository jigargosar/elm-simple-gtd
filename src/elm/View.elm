module View exposing (appView)

import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, h1, h2, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, class, classList, id, style, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.Internal as Model
import Model.EditMode
import Model.RunningTodo exposing (RunningTodoViewModel)
import Msg exposing (Msg)
import Set
import Entity.ViewModel
import View.EntityList
import View.AppDrawer exposing (appDrawerView)
import Maybe.Extra as Maybe
import Polymer.Attributes exposing (icon)
import Time exposing (Time)
import Ext.Time
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import Json.Decode
import Json.Encode
import List.Extra as List
import Model.Types exposing (..)
import Todo
import Polymer.Paper exposing (..)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.Todo


appView m =
    div []
        [ appDrawerLayoutView m
        , addTodoFabView m
        ]


appDrawerLayoutView m =
    let
        contextVM =
            Entity.ViewModel.context m

        projectVM =
            Entity.ViewModel.project m

        contextVMs =
            contextVM.vmList

        projectVMs =
            projectVM.vmList
    in
        App.drawerLayout []
            [ appDrawerView contextVM projectVM m
            , App.headerLayout []
                [ appHeaderView m
                , syncView m
                , appMainView contextVMs projectVMs m
                ]
            ]


syncView m =
    material []
        [ input [ value m.myPeerId ] []
        , input [ onInput Msg.SyncIdChanged, value m.syncId ] []
        , button [ onClick Msg.StartSync ] [ text "sync" ]
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
            , headerView m
            ]

        --        , runningTodoView m
        ]


runningTodoView : Model -> Html Msg
runningTodoView m =
    case Model.RunningTodo.getRunningTodoViewModel m of
        Just taskVm ->
            div [ class "active-task-view", attribute "sticky" "true" ] [ runningTodoViewHelp taskVm m ]

        Nothing ->
            div [ class "active-task-view", attribute "sticky" "true" ] []


runningTodoViewHelp : RunningTodoViewModel -> Model -> Html Msg
runningTodoViewHelp { todoVM, elapsedTime } m =
    div []
        [ div [ class "title" ] [ text todoVM.text ]
        , div [ class "col" ]
            [ div [ class "elapsed-time" ] [ text (Ext.Time.toHHMMSS elapsedTime) ]
            , iconButton [ icon "av:pause" ] []
            , iconButton [ icon "av:stop", Msg.stop |> onClick ] []
            , iconButton [ icon "check", Msg.stopAndMarkDone |> onClick ] []
            ]
        ]


appMainView contextVMs projectVMs m =
    div [ id "main-view" ]
        [ case Model.getMainViewType m of
            GroupByContextView ->
                View.EntityList.groupByEntity contextVMs m

            GroupByProjectView ->
                View.EntityList.groupByEntity projectVMs m

            ProjectView id ->
                View.EntityList.singletonEntity projectVMs id m

            ContextView id ->
                View.EntityList.singletonEntity contextVMs id m

            BinView ->
                View.EntityList.filtered m

            DoneView ->
                View.EntityList.filtered m
        ]


newTodoInputId =
    "new-todo-input"


headerView m =
    let
        selectedTodoCount =
            Model.getSelectedTodoIdSet m |> Set.size
    in
        case Model.getEditMode m of
            EditMode.NewTodo text ->
                input
                    [ id newTodoInputId
                    , class "auto-focus"
                    , onInput Msg.onNewTodoInput
                    , value text
                    , onBlur Msg.DeactivateEditingMode
                    , onKeyUp (Msg.NewTodoKeyUp text)
                    , stringProperty "label" "New Todo"
                    , boolProperty "alwaysFloatLabel" True
                    , style [ ( "width", "100%" ), "color" => "white" ]
                    ]
                    []

            EditMode.SwitchView ->
                span [] [ "Switch View: (A)ll, (P)rojects, (D)one, (B)in, (G)roup By." |> text ]

            EditMode.SwitchToGroupedView ->
                span [] [ "Group By: (P)rojects, (C)ontexts " |> text ]

            _ ->
                if selectedTodoCount == 0 then
                    h1 [ id "toolbar-title" ] [ text "SimpleGTD - alpha" ]
                else
                    span []
                        [ "(" ++ (toString selectedTodoCount) ++ ")" |> text
                        , iconButton
                            [ icon "done-all"
                            , onClick Msg.SelectionDoneClicked
                            ]
                            []
                        , iconButton
                            [ icon "create"
                            , onClick Msg.SelectionEditClicked
                            ]
                            []
                        , iconButton
                            [ icon "delete"
                            , onClick Msg.SelectionTrashClicked
                            ]
                            []
                        , iconButton
                            [ icon "cancel"
                            , onClick Msg.ClearSelection
                            ]
                            []
                        ]


addTodoFabView m =
    fab
        [ id "add-fab"
        , attribute "icon" "add"
        , onClick Msg.StartAddingTodo
        ]
        []


type alias TodoViewModel =
    Todo.Model
