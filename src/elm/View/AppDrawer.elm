module View.AppDrawer exposing (..)

import Document
import Entity
import OldGroupEntity.ViewModel
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, a, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, href, id, style, tabindex, target, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model exposing (Msg(SwitchView), commonMsg)
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
import Model exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (iconA, onBoolPropertyChanged, paperIconButton)


view : ViewModel.Model -> Model.Model -> Html Msg
view viewModel m =
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
                            , onClick Model.ToggleDrawer
                            ]
                            []
                        ]
                    , leftHeader m
                    ]
                ]
            , navList viewModel m
            ]
        ]


changeLogURL =
    "https://github.com/jigargosar/elm-simple-gtd/blob/master/CHANGELOG.md"


forumsURL =
    "https://groups.google.com/forum/#!forum/simplegtd"


newPostURL =
    "https://groups.google.com/forum/#!newtopic/simplegtd"


newIssueURL =
    "https://github.com/jigargosar/elm-simple-gtd/issues/new"


leftHeader m =
    let
        ( t1, t2 ) =
            if m.developmentMode then
                ( "Dev v" ++ m.appVersion, "v" ++ m.appVersion )
            else
                ( "SimpleGTD.com", "v" ++ m.appVersion )
    in
        div [ id "left-header" ]
            [ div [] [ text t1 ]
            , div [ class "small layout horizontal " ]
                [ a [ target "_blank", href changeLogURL ]
                    [ "v" ++ m.appVersion |> text ]
                , a [ target "_blank", href newPostURL ] [ text "Discuss" ]

                {- , a [ target "_blank", href newIssueURL ] [ text "Report Issue" ] -}
                , a [ target "_blank", href "mailto:jigar.gosar@gmail.com" ] [ text "Email Author" ]
                ]
            ]


navList viewModel m =
    let
        { contexts, projects } =
            viewModel
    in
        Html.node "paper-listbox"
            [ stringProperty "selectable" "paper-item"
            , intProperty "selected" (getSelectedIndex m.mainViewType viewModel)
            ]
            (entityListView contexts m.mainViewType
                ++ [ divider ]
                ++ entityListView projects m.mainViewType
                ++ [ divider ]
                ++ [ onSetEntityListView "delete" Entity.BinView "Bin"
                   , onSetEntityListView "done" Entity.DoneView "Done"
                   , switchViewItem "notification:sync" SyncView "Custom Sync"
                   ]
            )


getSelectedIndex mainViewType { projects, contexts } =
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
            EntityListView viewType ->
                case viewType of
                    Entity.ContextsView ->
                        0

                    Entity.ContextView id ->
                        1 + (contextIndexById id)

                    Entity.ProjectsView ->
                        projectsIndex

                    Entity.ProjectView id ->
                        1 + projectsIndex + (projectIndexById id)

                    Entity.BinView ->
                        lastProjectIndex + 1

                    Entity.DoneView ->
                        lastProjectIndex + 2

            SyncView ->
                lastProjectIndex + 3


divider =
    div [ class "divider" ] []


entityListView { entityList, viewType, title, showDeleted, onAddClicked, icon } mainViewType =
    [ item [ class "has-hover-elements" ]
        [ Html.node "iron-icon" [ iconA icon.name, style [ "color" => icon.color ] ] []
        , itemBody [ onClick (SwitchView (EntityListView viewType)) ] [ headLineText title ]
        , div [ class "show-on-hover layout horizontal center" ]
            [ toggleButton [ checked showDeleted, onClick Model.ToggleShowDeletedEntity ] []
            , WebComponents.icon "delete" []
            , iconButton [ iconA "add", onClickPreventDefaultAndStopPropagation onAddClicked ] []
            ]
        ]

    --    , divider
    ]
        ++ (List.map entityListItem entityList)


entityListItem : OldGroupEntity.ViewModel.DocumentWithNameViewModel -> Html Msg
entityListItem vm =
    item [ onClick (vm.onActiveStateChanged True) ]
        [ Html.node "iron-icon" [ iconA vm.icon.name, style [ "color" => vm.icon.color ] ] []
        , itemBody [] [ View.Shared.defaultBadge vm ]
        , div [ class "show-on-hover" ]
            [ WebComponents.iconButton "settings" [ onClick vm.startEditingMsg ]
            ]
        ]


headLineText title =
    div [ class "big-paper-item-text" ] [ text title ]


switchViewItem iconName viewType title =
    item [ onClick (SwitchView viewType) ]
        [ Html.node "iron-icon" [ iconA iconName ] []
        , itemBody [] [ text title ]
        ]


onSetEntityListView iconName viewType title =
    item [ onClick (OnSetEntityListView viewType) ]
        [ Html.node "iron-icon" [ iconA iconName ] []
        , itemBody [] [ text title ]
        ]
