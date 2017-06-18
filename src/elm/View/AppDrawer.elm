module View.AppDrawer exposing (..)

import AppDrawer.List
import Document
import Entity
import OldGroupEntity.ViewModel
import Html.Attributes.Extra exposing (..)
import Html.Events.Extra exposing (onClickPreventDefaultAndStopPropagation, onClickStopPropagation)
import Html.Keyed as Keyed
import Html exposing (Attribute, Html, a, div, hr, node, span, text)
import Html.Attributes exposing (attribute, autofocus, checked, class, classList, href, id, style, tabindex, target, value)
import Html.Events exposing (..)
import Ext.Keyboard as Keyboard exposing (onEscape, onKeyUp)
import Model exposing (Msg(SwitchView), commonMsg)
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
import Model exposing (..)
import View.Shared exposing (..)
import ViewModel
import WebComponents exposing (iconA, onBoolPropertyChanged, paperIconButton)


view : ViewModel.Model -> Model.Model -> Html Msg
view appVM model =
    App.drawer
        [ boolProperty "swipeOpen" True
        , attribute "slot" "drawer"
        ]
        [ App.headerLayout
            [ attribute "has-scrolling-region" ""
            ]
            [ App.header
                [ boolProperty "fixed" True
                , attribute "slot" "header"
                ]
                [ App.toolbar
                    [ style
                        [ "color" => "white"
                        , "background-color" => appVM.header.backgroundColor
                        ]
                    ]
                    [ div []
                        [ paperIconButton
                            [ iconA "menu"
                            , tabindex -1
                            , attribute "drawer-toggle" ""
                            , onClick Model.ToggleDrawer
                            ]
                            []
                        ]
                    , leftHeader model
                    ]
                ]
            , AppDrawer.List.view appVM model
            ]
        ]


changeLogURL =
    "https://github.com/jigargosar/elm-simple-gtd/blob/master/CHANGELOG.md"


forumsURL =
    "https://groups.google.com/forum/#!forum/simplegtd"


newPostURL =
    "https://groups.google.com/forum/#!newtopic/simplegtd"


newIssueURL =
    "https://github.com/jigargosar/elm-simple-gtd/issues/new"


leftHeader m =
    let
        ( t1, t2 ) =
            if m.developmentMode then
                ( "Dev v" ++ m.appVersion, "v" ++ m.appVersion )
            else
                ( "SimpleGTD.com", "v" ++ m.appVersion )
    in
        div [ id "left-header" ]
            [ div [] [ text t1 ]
            , div [ class "small layout horizontal " ]
                [ a [ target "_blank", href changeLogURL, tabindex -1 ]
                    [ "v" ++ m.appVersion |> text ]
                , a [ target "_blank", href newPostURL, tabindex -1 ]
                    [ text "Discuss" ]
                , a [ target "_blank", href "mailto:jigar.gosar@gmail.com", tabindex -1 ]
                    [ text "Feedback" ]
                ]
            ]
