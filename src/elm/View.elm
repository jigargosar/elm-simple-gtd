module View exposing (appView)

import EditMode
import Html.Attributes.Extra exposing (..)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, type_, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model.Internal as Model
import Model.RunningTodo exposing (RunningTodoViewModel)
import Msg exposing (Msg)
import ReminderOverlay
import Set
import Entity.ViewModel
import View.EntityList
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
import View.Todo
import ViewModel
import WebComponents exposing (doneAllIconP, icon, iconButton, iconP, iconTextButton, paperIconButton, testDialog)


appView m =
    div []
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
        ]
        [ App.toolbar
            [ style [ "color" => "white", "background-color" => viewModel.header.backgroundColor ]
            ]
            [ paperIconButton [ iconP "menu", attribute "drawer-toggle" "", onClick Msg.ToggleDrawer ] []
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


appMainView contextVMs projectVMs m =
    div [ id "main-view", class "" ]
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

            SyncView ->
                let
                    form =
                        Model.getRemoteSyncForm m
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
                Paper.input
                    [ id newTodoInputId
                    , class "auto-focus"
                    , onInput Msg.NewTodoTextChanged
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
        ]
        []
