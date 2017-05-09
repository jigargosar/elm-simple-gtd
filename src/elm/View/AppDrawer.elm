module View.AppDrawer exposing (..)

import Document
import Entity.ViewModel
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, id, style, tabindex, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Msg exposing (Msg(SetView), commonMsg)
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
import Types exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (iconA, onBoolPropertyChanged, paperIconButton)


view : ViewModel.Model -> Types.Model -> Html Msg
view viewModel m =
    let
        { contexts, projects } =
            viewModel
    in
        App.drawer
            [ boolProperty "swipeOpen" True
            , attribute "slot" "drawer"
            ]
            [ App.headerLayout
                [ attribute "has-scrolling-region" ""
                ]
                [ App.header
                    [ boolProperty "fixed" True
                    , attribute "slot" "header"
                    ]
                    [ App.toolbar
                        [ style
                            [ "color" => "white"
                            , "background-color" => viewModel.header.backgroundColor
                            ]
                        ]
                        [ div []
                            [ paperIconButton
                                [ iconA "menu"
                                , tabindex -1
                                , attribute "drawer-toggle" ""
                                , onClick Msg.ToggleDrawer
                                ]
                                []
                            ]
                        , headLineText viewModel.viewName
                        ]
                    ]
                , navList viewModel m
                ]
            ]


navList viewModel m =
    let
        { contexts, projects } =
            viewModel
    in
        Html.node "paper-listbox"
            [ stringProperty "selectable" "paper-item"
            , intProperty "selected" (getSelectedIndex viewModel)

            --                , stringProperty "attrForSelected" "draweritemselected"
            ]
            (entityListView contexts m.mainViewType
                ++ [ divider ]
                ++ entityListView projects m.mainViewType
                ++ [ divider ]
                ++ [ switchViewItem "delete" BinView "Bin"
                   , switchViewItem "done" DoneView "Done"
                   , switchViewItem "notification:sync" SyncView "Sync Settings"
                   ]
            )


getSelectedIndex { mainViewType, projects, contexts } =
    let
        projectsIndex =
            1 + (List.length contexts.entityList)

        contextIndexById id =
            contexts.entityList |> List.findIndex (.id >> equals id) >>?= 0

        projectIndexById id =
            projects.entityList |> List.findIndex (.id >> equals id) >>?= 0

        lastProjectIndex =
            projectsIndex + (List.length projects.entityList)
    in
        case mainViewType of
            GroupByContextView ->
                0

            ContextView id ->
                1 + (contextIndexById id)

            GroupByProjectView ->
                projectsIndex

            ProjectView id ->
                1 + projectsIndex + (projectIndexById id)

            BinView ->
                lastProjectIndex + 1

            DoneView ->
                lastProjectIndex + 2

            SyncView ->
                lastProjectIndex + 3


divider =
    div [ class "divider" ] []


entityListView { entityList, viewType, title, showDeleted, onAddClicked, icon } mainViewType =
    [ item
        [ class "has-hover-elements"
        , onClick (SetView viewType)
        ]
        [ Html.node "iron-icon" [ iconA icon.name, style [ "color" => icon.color ] ] []
        , itemBody [] [ headLineText title ]
        , div [ class "show-on-hover layout horizontal center" ]
            [ toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] []
            , WebComponents.icon "delete" []
            , iconButton [ iconA "add", onClick onAddClicked ] []
            ]
        ]

    --    , divider
    ]
        ++ (List.map entityListItem entityList)


entityListItem : Entity.ViewModel.EntityViewModel -> Html Msg
entityListItem vm =
    item [ onClick (vm.onActiveStateChanged True) ]
        [ Html.node "iron-icon" [ iconA vm.icon.name, style [ "color" => vm.icon.color ] ] []
        , itemBody [] [ View.Shared.defaultBadge vm ]
        , div [ class "show-on-hover" ] [ settingsButton vm.startEditingMsg ]
        ]


headLineText title =
    div [ class "big-paper-item-text" ] [ text title ]


switchViewItem iconName viewType title =
    item [ onClick (SetView viewType) ]
        [ Html.node "iron-icon" [ iconA iconName ] []
        , itemBody [] [ text title ]
        ]
