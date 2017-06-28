module AppDrawer.View exposing (..)

import AppColors
import AppUrl
import Polymer.App
import X.Html exposing (boolProperty, onClickStopPropagation)
import Material
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Entity
import AppDrawer.GroupViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Model exposing (Msg(OnSetViewType), commonMsg)
import Toolkit.Operators exposing (..)
import Model exposing (..)
import X.Function.Infix exposing (..)
import Model exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (paperIconButton)


view : ViewModel.Model -> Model.Model -> Html Msg
view appVM model =
    Polymer.App.drawer
        [ boolProperty "swipeOpen" True
        , attribute "slot" "drawer"
        ]
        [ Polymer.App.headerLayout
            [ attribute "has-scrolling-region" ""
            ]
            [ Polymer.App.header
                [ boolProperty "fixed" True
                , attribute "slot" "header"
                , class "app-main-header"
                ]
                [ Polymer.App.toolbar
                    [ style
                        [ "color" => "white"
                        , "background-color" => AppColors.encode appVM.header.backgroundColor
                        ]
                    ]
                    [ div []
                        [ paperIconButton
                            [ WebComponents.iconA "menu"
                            , tabindex -1
                            , attribute "drawer-toggle" ""
                            , onClick Model.ToggleDrawer
                            ]
                            []
                        ]
                    , sidebarHeader appVM model
                    ]
                ]
            , sidebarContent appVM model
            ]
        ]


sidebarHeader appVM m =
    let
        ( t1, t2 ) =
            if m.developmentMode then
                ( "Dev v" ++ m.appVersion, "v" ++ m.appVersion )
            else
                ( "SimpleGTD.com", "v" ++ m.appVersion )
    in
        div
            [ id "sidebar-header"
            , style
                [ "color" => "white"
                , "background-color" => AppColors.encode appVM.header.backgroundColor
                ]
            ]
            [ {- Material.iconButton "menu"
                     [ class "menu-btn"
                     , tabindex -1
                     , onClick Model.ToggleDrawer
                     ]
                 ,
              -}
              div [ class "detail" ]
                [ h5 [ href AppUrl.landing ] [ text t1 ]
                , div [ class "small layout horizontal " ]
                    [ a [ target "_blank", href AppUrl.changeLogURL, tabindex -1 ]
                        [ "v" ++ m.appVersion |> text ]
                    , a [ target "_blank", href AppUrl.newPostURL, tabindex -1 ]
                        [ text "Discuss" ]
                    , a [ target "_blank", href AppUrl.contact, tabindex -1 ]
                        [ text "Feedback" ]
                    ]
                ]
            ]


sidebarContent appVM model =
    let
        { contexts, projects } =
            appVM
    in
        div [ class "sidebar-content app-drawer-list-container" ]
            [ ul []
                ([]
                    ++ entityGroupView contexts model.mainViewType
                    ++ entityGroupView projects model.mainViewType
                    ++ [ Material.divider ]
                    ++ [ onSetEntityListViewItem "sort" Entity.RecentView "Recent"
                       , onSetEntityListViewItem "delete" Entity.BinView "Bin"
                       , onSetEntityListViewItem "done" Entity.DoneView "Done"
                       , Material.divider
                       , switchViewItemSmall "settings" SyncView "Advance Settings"
                       ]
                 --                    ++ [ toggleDeletedItem model ]
                )
            ]


toggleDeletedItem model =
    li [ onClick Model.ToggleShowDeletedEntity ]
        [ div [ class "switch" ]
            [ label []
                [ input
                    [ type_ "checkbox"
                    , checked model.showDeleted
                    , tabindex -1
                    , onClick Model.ToggleShowDeletedEntity
                    ]
                    []
                , span [ class "lever" ] []
                ]
            ]
        , div [] [ text "Show/Hide Deleted Contexts/Projects" ]
        ]


entityGroupView vm mainViewType =
    let
        { viewType, onAddClicked, onToggleExpanded, isExpanded } =
            vm

        isCurrentView =
            EntityListView viewType == mainViewType

        fireSwitchView =
            OnSetViewType (EntityListView viewType)

        fireSmart =
            if isCurrentView then
                onToggleExpanded
            else
                fireSwitchView

        expandIconName =
            if isExpanded then
                "expand_less"
            else
                "expand_more"

        nullViewAsList =
            vm.nullVMAsList .|> entityListItem
    in
        nullViewAsList
            ++ [ li [ onClick fireSmart ]
                    [ Material.iconA vm.icon.name [ style [ "color" => AppColors.encode vm.icon.color ] ]
                    , Html.h5 [] [ text vm.title ]
                    , Material.iconButton expandIconName [ onClickStopPropagation onToggleExpanded ]
                    ]
               , li [ classList [ "list-container" => True, "expanded" => isExpanded ] ]
                    [ ul []
                        ([]
                            ++ List.map entityListItem vm.entityList
                            ++ [ li
                                    [ class ""
                                    , X.Html.onClickStopAll onAddClicked
                                    ]
                                    [ Material.icon "add"
                                    , div [] [ text "Add New" ]
                                    ]
                               ]
                            ++ archivedItems vm
                         --                            ++ [ Material.divider ]
                        )
                    ]
               ]


archivedItems vm =
    let
        badgeCount =
            (vm.archivedEntityList |> List.length)

        ( iconName, buttonText, viewItems ) =
            if vm.showArchived then
                ( "visibility_off"
                , "Hide Archived"
                , List.map entityListItem vm.archivedEntityList
                )
            else
                ( "visibility"
                , " Show Archived"
                , []
                )
    in
        [ li
            [ class ""
            , onClick vm.onToggleShowArchived
            ]
            [ Material.icon iconName
            , div [ class "font-nowrap" ]
                [ View.Shared.badge buttonText badgeCount
                ]
            ]
        , li [ classList [ "list-container" => True, "expanded" => vm.showArchived ] ]
            [ ul [] viewItems ]
        ]


entityListItem : AppDrawer.GroupViewModel.DocumentWithNameViewModel -> Html Msg
entityListItem vm =
    li
        [ onClick (vm.onActiveStateChanged True)
        ]
        [ Material.iconA vm.icon.name [ style [ "color" => AppColors.encode vm.icon.color ] ]
        , div [ class "font-nowrap" ] [ View.Shared.defaultBadge vm ]
        ]


switchViewItem iconName viewType title =
    li
        [ class ""
        , onClick (OnSetViewType viewType)
        ]
        [ Material.icon iconName
        , h5 [] [ text title ]
        ]


switchViewItemSmall iconName viewType title =
    li
        [ class ""
        , onClick (OnSetViewType viewType)
        ]
        [ Material.icon iconName
        , div [] [ text title ]
        ]


onSetEntityListViewItem iconName viewType title =
    li
        [ class ""
        , onClick (OnSetEntityListView viewType)
        ]
        [ Material.icon iconName
        , h5 [] [ text title ]
        ]
