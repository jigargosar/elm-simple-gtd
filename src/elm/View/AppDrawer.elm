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
import Model.TodoStore
import Msg exposing (Msg(SetView))
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
import Model.Types exposing (..)
import View.Shared exposing (..)
import WebComponents exposing (iconP, onBoolPropertyChanged, paperIconButton)


view contextsVM projectVM m =
    App.drawer
        [ boolProperty "swipeOpen" True
        ]
        [ App.headerLayout
            [ attribute "has-scrolling-region" ""
            ]
            [ App.header
                [ boolProperty "fixed" True
                ]
                [ App.toolbar []
                    [ div []
                        [ paperIconButton
                            [ iconP "menu"
                            , attribute "drawer-toggle" ""
                            , onClick Msg.ToggleDrawer
                            ]
                            []
                        ]
                    , headLineText (getViewName m.mainViewType projectVM contextsVM)
                    ]
                ]
            , Html.node "paper-listbox"
                [ stringProperty "selectable" "paper-item"
                , intProperty "selected" (getSelectedIndex m.mainViewType projectVM contextsVM)

                --                , stringProperty "attrForSelected" "draweritemselected"
                ]
                (entityList contextsVM m.mainViewType
                    ++ [ divider ]
                    ++ entityList projectVM m.mainViewType
                    ++ [ divider ]
                    ++ [ switchViewItem "delete" BinView "Bin"
                       , switchViewItem "done" DoneView "Done"
                       , switchViewItem "notification:sync" SyncView "Sync Settings"
                       ]
                )
            ]
        ]


getViewName mainViewType projectVM contextsVM =
    let
        contextNameById id =
            contextsVM.entityList |> List.find (.id >> equals id) >>? .name >>? (++) "@" >>?= ""

        projectNameById id =
            projectVM.entityList |> List.find (.id >> equals id) >>? .name >>? (++) "#" >>?= ""
    in
        case mainViewType of
            GroupByContextView ->
                contextsVM.title

            ContextView id ->
                contextNameById id

            GroupByProjectView ->
                projectVM.title

            ProjectView id ->
                projectNameById id

            BinView ->
                "Bin"

            DoneView ->
                "Done"

            SyncView ->
                "Sync"


getSelectedIndex mainViewType projectVM contextsVM =
    let
        projectsIndex =
            1 + (List.length contextsVM.entityList)

        contextIndexById id =
            contextsVM.entityList |> List.findIndex (.id >> equals id) >>?= 0

        projectIndexById id =
            projectVM.entityList |> List.findIndex (.id >> equals id) >>?= 0

        lastProjectIndex =
            projectsIndex + (List.length projectVM.entityList)
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


entityList { entityList, viewType, title, showDeleted, onAddClicked, icon } mainViewType =
    [ item
        [ class "has-hover-elements"
        , onClick (SetView viewType)
        ]
        [ Html.node "iron-icon" [ iconP icon.name, style [ "color" => icon.color ] ] []
        , itemBody [] [ headLineText title ]
        , div [ class "show-on-hover layout horizontal center" ]
            [ toggleButton [ checked showDeleted, onClick Msg.ToggleShowDeletedEntity ] []
            , trashIcon
            , iconButton [ iconP "add", onClick onAddClicked ] []
            ]
        ]

    --    , divider
    ]
        ++ (List.map entityItem entityList)


headLineText title =
    div [ class "big-paper-item-text" ] [ text title ]


switchViewItem iconName viewType title =
    item [ onClick (SetView viewType) ]
        [ Html.node "iron-icon" [ iconP iconName ] []
        , itemBody [] [ text title ]
        ]



--onPropertyChanged decoder propertyName tagger =


entityItem : Entity.ViewModel.EntityItemModel -> Html Msg
entityItem vm =
    item [ onClick (vm.onActiveStateChanged True) ]
        ([ Html.node "iron-icon" [ iconP vm.icon.name, style [ "color" => vm.icon.color ] ] []
         , itemBody [] [ View.Shared.defaultBadge vm ]
         , hoverIcons vm
         , hideOnHover vm.isDeleted [ trashButton Msg.NoOp ]
         ]
        )


hoverIcons vm =
    div [ class "show-on-hover" ]
        [ settingsButton vm.startEditingMsg ]
