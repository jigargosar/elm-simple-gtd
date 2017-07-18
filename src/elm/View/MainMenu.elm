module View.MainMenu exposing (..)

import AppUrl
import Firebase
import Firebase.Types exposing (FirebaseMsg(OnFBSignIn, OnFBSignOut))
import Html exposing (..)
import Html.Attributes exposing (..)
import Menu.Types exposing (MenuState)
import Msg
import Menu
import Toolkit.Operators exposing (..)
import Model
import Tuple2
import Types exposing (AppModel)
import Msg


type ItemType
    = URL String
    | Msg Msg.AppMsg


type alias Item =
    ( String, ItemType )


menuConfig : MenuState -> AppModel -> Menu.Config Item Msg.AppMsg
menuConfig menuState appModel =
    { onSelect = onSelect
    , isSelected = (\_ -> False)
    , itemKey = Tuple.first
    , itemSearchText = Tuple.first
    , itemView = itemView
    , onStateChanged = Msg.onMainMenuStateChanged
    , noOp = Msg.noop
    , onOutsideMouseDown = Msg.revertExclusiveMode
    }


itemView ( textV, itemType ) =
    case itemType of
        URL url ->
            a [ href url, target "_blank" ] [ text textV ]

        Msg _ ->
            text textV


onSelect ( _, itemType ) =
    case itemType of
        URL url ->
            Msg.revertExclusiveMode

        Msg msg ->
            msg


getItems : AppModel -> List Item
getItems appModel =
    let
        maybeUserProfile =
            Firebase.getMaybeUserProfile appModel

        signInMenuItem =
            maybeUserProfile
                ?|> (\_ -> ( "SignOut", OnFBSignOut ))
                ?= ( "SignIn", OnFBSignIn )
                |> Tuple2.map (Msg.OnFirebaseMsg >> Msg)

        linkMenuItems =
            [ ( "Forums", URL AppUrl.forumsURL )
            , ( "Changelog v" ++ appModel.appVersion, URL AppUrl.changeLogURL )
            , ( "Github", URL AppUrl.github )
            ]
    in
        signInMenuItem :: linkMenuItems


init menuState appModel =
    Menu.view (getItems appModel)
        menuState
        (menuConfig menuState appModel)
