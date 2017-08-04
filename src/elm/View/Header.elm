module View.Header exposing (appMainHeader)

import Colors
import Firebase
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import X.Function.Infix exposing (..)


appMainHeader config frameVM m =
    let
        content =
            titleHeaderContent frameVM
    in
    div
        [ id "layout-main-header"
        , style
            [ "color" => "white"
            , "background-color" => Colors.toRBGAString frameVM.headerBackgroundColor
            ]
        ]
        (headerWithContent config content m)


titleHeaderContent frameVM =
    let
        titleText =
            frameVM.viewName
    in
    [ h5 [ class "ellipsis title", title titleText ] [ titleText |> text ]
    ]


headerWithContent config content m =
    let
        menuButton =
            Mat.headerIconBtn config.onMdl
                m.mdl
                [ Mat.resourceId "center-header-menu"
                , Mat.tabIndex -1
                , Mat.cs "menu-btn"
                , Mat.onClickStopPropagation config.onToggleAppDrawerOverlay
                ]
                [ Mat.icon "menu" ]
    in
    [ menuButton
    , div [ class "flex-auto font-nowrap" ] content
    , div [ id "main-menu-button", onClick config.onShowMainMenu ] [ menuIcon config m ]
    ]


menuIcon config m =
    case Firebase.getMaybeUserProfile m of
        Nothing ->
            Mat.headerIconBtn config.onMdl
                m.mdl
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
