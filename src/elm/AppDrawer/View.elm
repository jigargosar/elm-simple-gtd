module AppDrawer.View exposing (..)

import AppColors
import AppUrl
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import Toolkit.Operators exposing (..)
import View.Badge
import X.Function.Infix exposing (..)
import X.Html


sidebarHeader appVM m =
    let
        t1 =
            if m.developmentMode then
                "Dev v" ++ m.appVersion
            else
                "SimpleGTD.com"
    in
    div
        [ id "layout-sidebar-header"
        , style
            [ "color" => "white"
            , "background-color" => AppColors.encode appVM.header.backgroundColor
            ]
        ]
        [ div [ class "detail" ]
            [ h5 [] [ a [ href AppUrl.landing, tabindex -1 ] [ text t1 ] ]
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


sidebarContent config appVM model =
    let
        { contexts, projects } =
            appVM
    in
    div [ id "layout-sidebar-content", class "app-drawer-list-container" ]
        [ ul []
            ([]
                ++ entityGroupView config contexts model.page
                ++ entityGroupView config projects model.page
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
                   , Mat.divider
                   , switchViewItemSmall
                        config
                        "settings"
                        [ "custom-sync" ]
                        "Advance Settings"
                   ]
            )
        ]


entityGroupView config vm page =
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


switchViewItemSmall config iconName path title =
    li
        [ class ""
        , onClick (config.navigateToPathMsg path)
        ]
        [ Mat.icon iconName
        , div [] [ text title ]
        ]


onSetEntityListViewItem config icon page title =
    li
        [ class ""
        , onClick (config.navigateToPathMsg page)
        ]
        [ icon
        , h5 [] [ text title ]
        ]
