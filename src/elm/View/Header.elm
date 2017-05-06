module View.Header exposing (..)

import EditMode
import Ext.Keyboard exposing (..)
import Firebase
import Html.Attributes.Extra exposing (..)
import Model
import Msg
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


init m =
    let
        selectedTodoCount =
            Model.getSelectedTodoIdSet m |> Set.size
    in
        case m.editMode of
            EditMode.NewTodo form ->
                Paper.input
                    [ id newTodoInputId
                    , class "auto-focus"
                    , onInput Msg.NewTodoTextChanged
                    , value form.text
                    , onBlur Msg.DeactivateEditingMode
                    , onKeyUp (Msg.NewTodoKeyUp form)
                    , stringProperty "label" "New Todo"
                    , boolProperty "alwaysFloatLabel" True
                    , style [ ( "width", "100%" ), "color" => "white" ]
                    ]
                    []

            EditMode.SwitchView ->
                span [] [ "Switch View: (A)ll, (P)rojects, (D)one, (B)in, (G)roup By." |> text ]

            EditMode.SwitchToGroupedView ->
                span [] [ "Group By: (P)rojects, (C)ontexts " |> text ]

            _ ->
                if selectedTodoCount == 0 then
                    defaultHeader m
                else
                    selectionHeader selectedTodoCount


defaultHeader m =
    let
        title =
            if m.developmentMode then
                "DEVELOPMENT MODE"
            else
                "SimpleGTD - alpha"

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
                [ Paper.menuButton [ dynamicAlign, boolProperty "noOverlap" True ]
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


selectionHeader selectedTodoCount =
    span []
        [ "(" ++ (toString selectedTodoCount) ++ ")" |> text
        , iconButton "done-all"
            [ onClick Msg.SelectionDoneClicked
            ]
        , iconButton "create"
            [ onClick Msg.SelectionEditClicked
            ]
        , iconButton "delete"
            [ onClick Msg.SelectionTrashClicked
            ]
        , iconButton "cancel"
            [ onClick Msg.ClearSelection ]
        ]
