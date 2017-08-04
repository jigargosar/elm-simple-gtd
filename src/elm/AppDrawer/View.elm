module AppDrawer.View exposing (..)

import AppUrl
import Colors
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import Toolkit.Operators exposing (..)
import View.Badge
import X.Function.Infix exposing (..)
import X.Html


sidebarHeader frameVM =
    div
        [ id "layout-sidebar-header"
        , style
            [ "color" => "white"
            , "background-color" => Colors.toRBGAString frameVM.headerBackgroundColor
            ]
        ]
        [ div [ class "detail" ]
            [ h5 [] [ a [ href AppUrl.landing, tabindex -1 ] [ text frameVM.sidebarHeaderTitle ] ]
            , div [ class "small layout horizontal " ]
                [ a [ target "_blank", href AppUrl.changeLogURL, tabindex -1 ]
                    [ frameVM.appVersionString |> text ]
                , a [ target "_blank", href AppUrl.newPostURL, tabindex -1 ]
                    [ text "Discuss" ]
                , a [ target "_blank", href AppUrl.contact, tabindex -1 ]
                    [ text "Feedback" ]
                ]
            ]
        ]


sidebarContent config frameVM =
    div [ id "layout-sidebar-content", class "app-drawer-list-container" ]
        [ ul []
            ([]
                ++ entityGroupView config frameVM.contexts
                ++ entityGroupView config frameVM.projects
                ++ [ Mat.divider ]
                ++ [ onSetEntityListViewItem
                        config
                        (Mat.icon "sort")
                        [ "recent" ]
                        "Recent"
                   , onSetEntityListViewItem
                        config
                        (Mat.iconView "done" [ Mat.cs "done-icon", Mat.cs "is-done" ])
                        [ "done" ]
                        "Done"
                   , onSetEntityListViewItem
                        config
                        (Mat.icon "delete")
                        [ "bin" ]
                        "Bin"
                   ]
            )
        ]


entityGroupView config vm =
    let
        { onAddClicked, onToggleExpanded, isExpanded } =
            vm

        isCurrentView =
            -- todo: cleanup
            -- Old_EntityListPage vm.page == page
            False

        fireSwitchView =
            config.navigateToPathMsg vm.page

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
                [ Mat.iconM vm.icon
                , Html.h5 [] [ text vm.title ]
                , div []
                    [ Mat.iconBtn2 config.onMdl "add" onAddClicked
                    , Mat.iconBtn2 config.onMdl expandIconName onToggleExpanded
                    ]
                ]
           , li [ classList [ "list-container" => True, "expanded" => isExpanded ] ]
                [ ul []
                    ([]
                        ++ List.map entityListItem vm.entityList
                        ++ [ li
                                [ class ""
                                , X.Html.onClickStopAll onAddClicked
                                ]
                                [ Mat.icon "add"
                                , div [] [ text "Add New" ]
                                ]
                           ]
                        ++ archivedItems vm
                    )
                ]
           ]


archivedItems vm =
    let
        badgeCount =
            vm.archivedEntityList |> List.length

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
        [ Mat.icon iconName
        , div [ class "font-nowrap" ]
            [ View.Badge.badge buttonText badgeCount
            ]
        ]
    , li [ classList [ "list-container" => True, "expanded" => vm.showArchived ] ]
        [ ul [] viewItems ]
    ]



--entityListItem : AppDrawer.GroupViewModel.DocumentWithNameViewModel -> Html AppMsg


entityListItem vm =
    li
        [ onClick (vm.onActiveStateChanged True)
        ]
        [ Mat.iconM vm.icon
        , div [ class "font-nowrap" ] [ View.Badge.badge vm.name vm.count ]
        ]


onSetEntityListViewItem config icon page title =
    li
        [ class ""
        , onClick (config.navigateToPathMsg page)
        ]
        [ icon
        , h5 [] [ text title ]
        ]
