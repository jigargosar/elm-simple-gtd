module View exposing (init)

import Context
import Document
import Dom
import EditMode
import Firebase
import Firebase.View
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, form, h1, h2, hr, input, node, span, text)
import Html.Attributes exposing (action, attribute, autofocus, class, classList, id, method, required, style, tabindex, type_, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model
import Model exposing (Msg, commonMsg)
import Polymer.Firebase
import ReminderOverlay
import Set
import OldGroupEntity.ViewModel
import Todo.ProjectsForm
import View.Header
import Main.View
import View.TodoList
import View.AppDrawer
import Maybe.Extra as Maybe
import Time exposing (Time)
import Ext.Time
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Debug exposing (tapLog)
import Ext.Decode exposing (traceDecoder)
import List.Extra as List
import Model exposing (..)
import Todo
import Polymer.Paper as Paper exposing (dialog, material)
import Polymer.App as App
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import View.ReminderOverlay exposing (showReminderOverlay)
import View.Shared exposing (..)
import Todo.View
import ViewModel
import WebComponents exposing (doneAllIconP, dynamicAlign, icon, iconA, iconButton, iconTextButton, onBoolPropertyChanged, onPropertyChanged, paperIconButton, slotDropdownContent, slotDropdownTrigger, testDialog)
import Ext.Html
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import LaunchBar.View
import Menu
import Project


init m =
    div [ id "root" ]
        ([ Firebase.View.init m
         , appView m
         ]
        )


appView model =
    div [ id "app-view" ]
        ([ appDrawerLayoutView model
         , addTodoFab model
         , showReminderOverlay model
         , LaunchBar.View.init model
         ]
            ++ (overlayViews model)
        )


overlayViews m =
    contextMenu m
        ++ projectMenu m


createProjectMenuConfig : Model -> Todo.ProjectsForm.Model -> Menu.Config Project.Model Msg
createProjectMenuConfig model ({ todo, maybeFocusKey } as form) =
    { items = Model.getActiveProjects model
    , onSelect = Model.SetTodoProject # todo
    , isSelected = Document.hasId (Todo.getProjectId todo)
    , itemKey = Document.getId >> String.append "project-id-"
    , domId = "project-menu"
    , itemView = Project.getName >> text
    , maybeFocusKey = maybeFocusKey
    , onFocusIndexChanged = Model.UpdateEditTodoProjectMaybeFocusKey form
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


projectMenu : Model -> List (Html Msg)
projectMenu model =
    model
        |> Model.getMaybeEditTodoProjectForm
        ?|> (createProjectMenuConfig model >> Menu.view)
        |> Maybe.toList


createContextMenuConfig : Model -> Todo.Model -> Menu.Config Context.Model Msg
createContextMenuConfig model todo =
    { items = Model.getActiveContexts model
    , onSelect = Model.SetTodoContext # todo
    , isSelected = Document.hasId (Todo.getContextId todo)
    , itemKey = Document.getId >> String.append "context-id-"
    , domId = "context-menu"
    , itemView = Context.getName >> text
    , maybeFocusKey = Nothing
    , onFocusIndexChanged = (\_ -> commonMsg.noOp)
    , noOp = commonMsg.noOp
    , onOutsideMouseDown = Model.DeactivateEditingMode
    }


contextMenu : Model -> List (Html Msg)
contextMenu model =
    model
        |> Model.getMaybeEditTodoContextForm
        ?|> (createContextMenuConfig model >> Menu.view)
        |> Maybe.toList


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

        forceNarrow =
            Model.getLayoutForceNarrow m
    in
        App.drawerLayout
            [ boolProperty "forceNarrow" forceNarrow
            , onBoolPropertyChanged "narrow" Model.OnLayoutNarrowChanged
            ]
            [ View.AppDrawer.view viewModel m
            , App.headerLayout [ attribute "has-scrolling-region" "" ]
                [ View.Header.init viewModel m
                , Main.View.init viewModel m
                ]
            ]


addTodoFab m =
    Paper.fab
        [ id "add-fab"
        , attribute "icon" "add"
        , attribute "mini" ""
        , onClick Model.NewTodo
        , tabindex -1
        ]
        []
