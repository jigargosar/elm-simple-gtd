module View.Header exposing (..)

import EditMode
import Ext.Keyboard as Keyboard
import Ext.Time
import Firebase
import Html.Attributes.Extra exposing (..)
import Model
import Model.RunningTodo exposing (RunningTodoViewModel)
import Model.Types exposing (Model)
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
    App.header
        [ attribute "reveals" ""
        , attribute "condenses" ""

        --        , attribute "effects" "material"
        , attribute "effects" "waterfall"

        --        , attribute "fixed" "true"
        , attribute "slot" "header"
        ]
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

        --        , runningTodoView m
        ]


runningTodoView : Model -> Html Msg
runningTodoView m =
    case Model.RunningTodo.getRunningTodoViewModel m of
        Just taskVm ->
            div [ class "active-task-view", attribute "sticky" "true" ] [ runningTodoViewHelp taskVm m ]

        Nothing ->
            div [ class "active-task-view", attribute "sticky" "true" ] []


runningTodoViewHelp : RunningTodoViewModel -> Model -> Html Msg
runningTodoViewHelp { todoVM, elapsedTime } m =
    div []
        [ div [ class "title" ] [ text todoVM.text ]
        , div [ class "col" ]
            [ div [ class "elapsed-time" ] [ text (Ext.Time.toHHMMSS elapsedTime) ]
            , paperIconButton [ iconA "av:pause" ] []
            , paperIconButton [ iconA "av:stop", Msg.Stop |> onClick ] []
            , paperIconButton [ iconA "check", Msg.MarkRunningTodoDone |> onClick ] []
            ]
        ]


headerView m =
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
                    , Keyboard.onKeyUp (Msg.NewTodoKeyUp form)
                    , stringProperty "label" "New Todo"
                    , boolProperty "alwaysFloatLabel" True
                    , style [ ( "width", "100%" ), "color" => "white" ]
                    ]
                    []

            EditMode.SwitchView ->
                span [] [ "Switch View: (C)ontexts, (P)rojects, (D)one, (B)in." |> text ]

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
