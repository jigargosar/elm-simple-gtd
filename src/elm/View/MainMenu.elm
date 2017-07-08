module View.MainMenu exposing (..)

import AppUrl
import Firebase
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Menu.Types exposing (MenuState)
import Msg
import X.Html exposing (..)
import Menu
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Tuple2


type ItemType
    = URL String
    | Msg Msg.Msg


type alias Item =
    ( String, ItemType )


menuConfig : MenuState -> Model.Model -> Menu.Config Item Msg.Msg
menuConfig menuState appModel =
    { onSelect = onSelect
    , isSelected = (\_ -> False)
    , itemKey = Tuple.first
    , itemSearchText = Tuple.first
    , itemView = itemView
    , onStateChanged = Msg.OnMainMenuStateChanged
    , noOp = Model.noop
    , onOutsideMouseDown = Msg.OnDeactivateEditingMode
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
            Msg.OnDeactivateEditingMode

        Msg msg ->
            msg


getItems : Model.Model -> List Item
getItems appModel =
    let
        maybeUserProfile =
            Firebase.getMaybeUserProfile appModel

        signInMenuItem =
            maybeUserProfile
                ?|> (\_ -> ( "SignOut", Firebase.OnSignOut ))
                ?= ( "SignIn", Firebase.OnSignIn )
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
