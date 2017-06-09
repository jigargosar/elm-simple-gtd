module View.Header exposing (..)

import EditMode
import Ext.Keyboard as Keyboard
import Ext.Time
import Firebase
import Html.Attributes.Extra exposing (..)
import Model
import Todo.NewForm
import Model exposing (Model)
import Model exposing (Msg)
import Polymer.App as App
import Polymer.Paper as Paper
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Set
import WebComponents exposing (..)


init viewModel m =
    let
        fixedAttributeAsList =
            if Model.isLayoutAutoNarrow m then
                [ attribute "condenses" ""
                , attribute "reveals" ""
                ]
            else
                [ attribute "fixed" "" ]
    in
        App.header
            ([ id "main-header"
             , attribute "slot" "header"
             , attribute "effects" "waterfall"

             --             , attribute "effects" "material"
             ]
                ++ fixedAttributeAsList
            )
            [ App.toolbar
                [ style [ "color" => "white", "background-color" => viewModel.header.backgroundColor ]
                ]
                (headerView viewModel m)
            ]


headerView viewModel m =
    case m.editMode of
        EditMode.NewTodo form ->
            [ div [ class "new-todo input-field" ]
                [ input
                    [ class "auto-focus"
                    , onInput (Model.NewTodoTextChanged form)
                    , form |> Todo.NewForm.getText |> defaultValue
                    , onBlur Model.DeactivateEditingMode
                    , Keyboard.onKeyUp Model.NewTodoKeyUp

                    --                    , stringProperty "label" "New Todo"
                    --                    , boolProperty "alwaysFloatLabel" True
                    --                    , style [ ( "width", "100%" ), "color" => "white" ]
                    ]
                    []
                , label [ class "active" ] [ text "New Todo" ]
                ]
            ]

        _ ->
            defaultHeader viewModel m


defaultHeader viewModel m =
    let
        title_ =
            if m.developmentMode then
                viewModel.viewName ++ " dev:" ++ m.appVersion
            else
                viewModel.viewName

        maybeUserProfile =
            Model.getMaybeUserProfile m

        userPhotoUrl =
            Model.getMaybeUserProfile m ?|> Firebase.getPhotoURL ?= ""

        userAccountAttribute =
            Model.getMaybeUserProfile m
                ?|> (Firebase.getPhotoURL >> attribute "src")
                ?= iconA "account-circle"

        userSignInLink =
            maybeUserProfile
                ?|> (\_ -> Paper.item [ onClick Model.SignOut ] [ text "SignOut" ])
                ?= Paper.item [ onClick Model.SignIn ] [ text "SignIn" ]
    in
        [ paperIconButton
            [ iconA "menu"
            , tabindex -1
            , attribute "drawer-toggle" ""
            , onClick Model.ToggleDrawer
            , class "hide-when-wide"
            ]
            []
        , h5 [ class "ellipsis title", title title_ ] [ title_ |> text ]
        , Paper.itemBody [] []
        , Paper.menuButton
            [ dynamicAlign
            , boolProperty "noOverlap" True
            , boolProperty "closeOnActivate" True
            ]
            [ Html.node "iron-icon"
                [ userAccountAttribute
                , class "account"
                , slotDropdownTrigger
                ]
                []
            , Paper.listbox [ class "", slotDropdownContent ]
                [ userSignInLink
                , Paper.item []
                    [ Paper.itemBody []
                        [ a
                            [ target "_blank"
                            , href "https://github.com/jigargosar/elm-simple-gtd/blob/master/CHANGELOG.md"
                            ]
                            [ text "Changelog v", text m.appVersion ]
                        ]
                    ]
                , Paper.item []
                    [ Paper.itemBody []
                        [ a
                            [ target "_blank"
                            , href "https://github.com/jigargosar/elm-simple-gtd"
                            ]
                            [ text "Github" ]
                        ]
                    ]
                ]
            ]
        ]
