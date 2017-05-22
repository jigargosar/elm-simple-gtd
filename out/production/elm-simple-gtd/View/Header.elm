module View.Header exposing (..)

import EditMode
import Ext.Keyboard as Keyboard
import Ext.Time
import Firebase
import Html.Attributes.Extra exposing (..)
import Model
import Todo.NewForm
import Model exposing (Model)
import Msg exposing (Msg)
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


newTodoInputId =
    "new-todo-input"


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
                [ paperIconButton
                    [ iconA "menu"
                    , tabindex -1
                    , attribute "drawer-toggle" ""
                    , onClick Msg.ToggleDrawer
                    , class "hide-when-wide"
                    ]
                    []
                , headerView m
                ]
            ]


headerView m =
    case m.editMode of
        EditMode.NewTodo form ->
            Paper.input
                [ id newTodoInputId
                , class "auto-focus"
                , onInput Msg.NewTodoTextChanged
                , form |> Todo.NewForm.getText |> value
                , onBlur Msg.DeactivateEditingMode
                , Keyboard.onKeyUp Msg.NewTodoKeyUp
                , stringProperty "label" "New Todo"
                , boolProperty "alwaysFloatLabel" True
                , style [ ( "width", "100%" ), "color" => "white" ]
                ]
                []

        _ ->
            defaultHeader m


defaultHeader m =
    let
        title =
            (if m.developmentMode then
                "DEV_ENV"
             else
                "SimpleGTD"
            )
                ++ " "
                ++ m.appVersion

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
                ?|> (\_ -> Paper.item [ onClick Msg.SignOut ] [ text "SignOut" ])
                ?= Paper.item [ onClick Msg.SignIn ] [ text "SignIn" ]
    in
        div [ class "flex-auto layout horizontal justified center" ]
            [ h2 [ class "ellipsis" ] [ title |> text ]
            , div []
                [ Paper.menuButton
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
                    , Paper.listbox [ slotDropdownContent ]
                        [ userSignInLink
                        ]
                    ]
                ]
            ]
