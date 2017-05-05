module View exposing (init)

import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.Internal as Model
import Model.RunningTodo exposing (RunningTodoViewModel)
import Msg exposing (Msg)
import Polymer.Firebase
import ReminderOverlay
import Set
import Entity.ViewModel
import Test.View
import View.TodoList
import View.AppDrawer
import Maybe.Extra as Maybe
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
import Polymer.Paper as Paper exposing (dialog, material)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (showReminderOverlay)
import View.Shared exposing (..)
import Todo.View
import ViewModel
import WebComponents exposing (doneAllIconP, icon, iconButton, iconP, iconTextButton, paperIconButton, testDialog)


init m =
    div [ id "root" ]
        [ firebaseView m
        , appView2 m
        ]


firebaseView m =
    div [ id "firebase-container" ]
        [ Html.node "firebase-auth" [ id "google-auth", attribute "provider" "google" ] [] ]


appView2 m =
    div [ id "app-view" ]
        [ appDrawerLayoutView m
        , addTodoFab m
        , showReminderOverlay m
        ]


bottomSheet =
    div [ class "full-view" ]
        [ Paper.material [ style [ "background-color" => "white" ], class "fixed-bottom", attribute "elevation" "5" ]
            [ Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            , Paper.item [] [ text "bottom" ]
            ]
        ]


appDrawerLayoutView m =
    let
        viewModel =
            ViewModel.create m

        { contexts, projects } =
            viewModel

        contextVMs =
            contexts.entityList

        projectVMs =
            projects.entityList
    in
        App.drawerLayout
            [ boolProperty "forceNarrow" m.appDrawerForceNarrow
            ]
            [ View.AppDrawer.view m viewModel
            , App.headerLayout [ attribute "has-scrolling-region" "" ]
                [ appHeaderView m viewModel
                , appMainView contextVMs projectVMs m
                ]
            ]


appHeaderView m viewModel =
    App.header
        [ attribute "reveals" ""
        , attribute "condenses" ""

        --        , attribute "effects" "material"
        , attribute "effects" "waterfall"

        --        , attribute "fixed" "true"
        , attribute "slot" "header"
        ]
        [ App.toolbar
            [ style [ "color" => "white", "background-color" => viewModel.header.backgroundColor ]
            ]
            [ paperIconButton
                [ iconP "menu"
                , tabindex -1
                , attribute "drawer-toggle" ""
                , onClick Msg.ToggleDrawer
                , class "hide-when-wide"
                ]
                []
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
            , paperIconButton [ iconP "av:pause" ] []
            , paperIconButton [ iconP "av:stop", Msg.Stop |> onClick ] []
            , paperIconButton [ iconP "check", Msg.MarkRunningTodoDone |> onClick ] []
            ]
        ]


appMainView contextVMs projectVMs model =
    div [ id "main-view", class "" ]
        [ case Model.getMainViewType model of
            GroupByContextView ->
                View.TodoList.groupByEntity contextVMs model

            GroupByProjectView ->
                View.TodoList.groupByEntity projectVMs model

            ProjectView id ->
                View.TodoList.groupByEntityWithId projectVMs id model

            ContextView id ->
                View.TodoList.groupByEntityWithId contextVMs id model

            BinView ->
                View.TodoList.filtered model

            DoneView ->
                View.TodoList.filtered model

            SyncView ->
                let
                    form =
                        Model.getRemoteSyncForm model
                in
                    Paper.material [ class "static layout" ]
                        [ Paper.input
                            [ attribute "label" "Cloudant URL or any CouchDB URL"
                            , value form.uri
                            , onInput (Msg.UpdateRemoteSyncFormUri form)
                            ]
                            []
                        , Paper.button [ form |> Msg.RemotePouchSync >> onClick ] [ text "Sync" ]
                        ]

            TestView ->
                Test.View.init model.testModel
        ]


newTodoInputId =
    "new-todo-input"


headerView m =
    let
        selectedTodoCount =
            Model.getSelectedTodoIdSet m |> Set.size
    in
        case Model.getEditMode m of
            EditMode.NewTodo form ->
                Paper.input
                    [ id newTodoInputId
                    , class "auto-focus"
                    , onInput Msg.NewTodoTextChanged
                    , value form.text
                    , onBlur Msg.DeactivateEditingMode
                    , onKeyUp (Msg.NewTodoKeyUp form)
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
                    h2 [ class "ellipsis" ] [ text "SimpleGTD - alpha" ]
                else
                    span []
                        [ "(" ++ (toString selectedTodoCount) ++ ")" |> text
                        , iconButton "done-all"
                            [ onClick Msg.SelectionDoneClicked
                            ]
                        , iconButton "create"
                            [ onClick Msg.SelectionEditClicked
                            ]
                        , iconButton "delete"
                            [ onClick Msg.SelectionTrashClicked
                            ]
                        , iconButton "cancel"
                            [ onClick Msg.ClearSelection ]
                        ]


addTodoFab m =
    Paper.fab
        [ id "add-fab"
        , attribute "icon" "add"
        , attribute "mini" ""
        , onClick Msg.StartAddingTodo
        , tabindex -1
        ]
        []
