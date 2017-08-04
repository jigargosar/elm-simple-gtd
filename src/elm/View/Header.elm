module View.Header exposing (appMainHeader)

import Colors
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import X.Function.Infix exposing (..)


appMainHeader config frameVM =
    div
        [ id "layout-main-header"
        , style
            [ "color" => "white"
            , "background-color" => Colors.toRBGAString frameVM.headerBackgroundColor
            ]
        ]
        [ sidebarMenuButton config frameVM
        , div [ class "flex-auto font-nowrap" ] [ headerTitle frameVM ]
        , div [ id "main-menu-button", onClick config.onShowMainMenu ]
            [ mainMenuProfileIcon config frameVM ]
        ]


headerTitle frameVM =
    let
        mainHeaderTitle =
            frameVM.mainHeaderTitle
    in
    h5 [ class "ellipsis title", title mainHeaderTitle ] [ mainHeaderTitle |> text ]


sidebarMenuButton config frameVM =
    Mat.headerIconBtn config.onMdl
        frameVM.mdl
        [ Mat.resourceId "center-header-menu"
        , Mat.tabIndex -1
        , Mat.cs "menu-btn"
        , Mat.onClickStopPropagation config.onToggleAppDrawerOverlay
        ]
        [ Mat.icon "menu" ]


mainMenuProfileIcon config frameVM =
    case frameVM.maybeUser of
        Nothing ->
            Mat.headerIconBtn config.onMdl
                frameVM.mdl
                [ Mat.resourceId "account-menu-not-signed-in"
                , Mat.tabIndex -1
                ]
                [ Mat.icon "account_circle" ]

        Just { photoURL } ->
            img
                [ src photoURL
                , class "account"
                ]
                []
