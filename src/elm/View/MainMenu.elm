module View.MainMenu exposing (..)

import AppUrl
import Firebase
import Firebase.Types exposing (FirebaseMsg(OnFBSignIn, OnFBSignOut))
import Html exposing (..)
import Html.Attributes exposing (..)
import Menu.Types exposing (MenuState)
import Menu
import Toolkit.Operators exposing (..)
import Tuple2


type ItemType msg
    = URLItem String
    | MsgItem msg


type alias Item =
    ( String, ItemType )



--menuConfig : MenuState -> AppModel -> Menu.Config Item Msg.AppMsg


menuConfig config menuState =
    { onSelect = onItemSelect config
    , isSelected = (\_ -> False)
    , itemKey = Tuple.first
    , itemSearchText = Tuple.first
    , itemView = itemView
    , onStateChanged = config.onMainMenuStateChanged
    , noOp = config.noop
    , onOutsideMouseDown = config.revertExclusiveMode
    }


itemView ( textV, itemType ) =
    case itemType of
        URLItem url ->
            a [ href url, target "_blank" ] [ text textV ]

        MsgItem _ ->
            text textV


onItemSelect config ( _, itemType ) =
    case itemType of
        URLItem url ->
            config.revertExclusiveMode

        MsgItem msg ->
            msg



--getItems : AppModel -> List Item


getItems config appModel =
    let
        maybeUserProfile =
            Firebase.getMaybeUserProfile appModel

        signInMenuItem =
            maybeUserProfile
                ?|> (\_ -> ( "SignOut", config.onSignOut ))
                ?= ( "SignIn", config.onSignIn )
                |> Tuple2.mapSecond MsgItem

        linkMenuItems =
            [ ( "Forums", URLItem AppUrl.forumsURL )
            , ( "Changelog v" ++ appModel.appVersion, URLItem AppUrl.changeLogURL )
            , ( "Github", URLItem AppUrl.github )
            ]
    in
        signInMenuItem :: linkMenuItems


init config menuState appModel =
    Menu.view (getItems config appModel)
        menuState
        (menuConfig config menuState)
