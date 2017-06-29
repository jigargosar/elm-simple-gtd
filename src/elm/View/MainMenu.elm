module View.MainMenu exposing (..)

import AppUrl
import Firebase
import Html
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
    | Msg Model.Msg


type alias Item =
    ( String, ItemType )


menuConfig : Menu.State -> Model.Model -> Menu.Config Item Model.Msg
menuConfig menuState appModel =
    { onSelect = onSelect
    , isSelected = (\_ -> False)
    , itemKey = Tuple.first
    , itemSearchText = Tuple.first
    , itemView = Tuple.first >> Html.text
    , onStateChanged = Model.OnMainMenuStateChanged
    , noOp = Model.noop
    , onOutsideMouseDown = Model.OnDeactivateEditingMode
    }


onSelect ( _, itemType ) =
    case itemType of
        URL url ->
            Model.OnDeactivateEditingMode

        Msg msg ->
            msg


getItems : Model.Model -> List Item
getItems appModel =
    let
        maybeUserProfile =
            Model.getMaybeUserProfile appModel

        signInMenuItem =
            maybeUserProfile
                ?|> (\_ -> ( "SignOut", Firebase.OnSignOut ))
                ?= ( "SignIn", Firebase.OnSignIn )
                |> Tuple2.map (Model.OnFirebaseMsg >> Msg)

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
