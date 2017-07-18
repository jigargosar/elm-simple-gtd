module Todo.View exposing (..)

import Context
import Date
import Document
import Entity.Types exposing (EntityId(TodoId))
import EntityId
import Material
import Msg exposing (AppMsg)
import Store
import Todo.FormTypes exposing (..)
import Todo.Types exposing (TodoDoc)
import TodoMsg
import X.Html exposing (onChange, onClickStopPropagation, onMouseDownStopPropagation)
import X.Time
import Keyboard.Extra as Key exposing (Key)
import List.Extra as List
import Mat
import Project
import Regex
import RegexHelper
import Set
import String.Extra as String
import Time exposing (Time)
import Todo
import Todo.Msg
import Todo.View.Menu
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import X.Keyboard exposing (KeyboardEvent, onEscape, onKeyDown, onKeyDownPreventDefault, onKeyDownStopPropagation, onKeyUp)
import View.Shared exposing (defaultOkCancelButtons, defaultOkCancelDeleteButtons)
import Msg


type alias TodoViewModel =
    { key : String
    , displayText : String
    , isDone : Bool
    , isDeleted : Bool
    , onKeyDownMsg : KeyboardEvent -> AppMsg
    , projectDisplayName : String
    , contextDisplayName : String
    , startEditingMsg : AppMsg
    , toggleDoneMsg : AppMsg
    , canBeFocused : Bool
    , showContextDropDownMsg : AppMsg
    , showProjectDropDownMsg : AppMsg
    , reminder : ScheduleViewModel
    , onFocusIn : AppMsg
    , tabindexAV : Int
    , isSelected : Bool
    , mdl : Material.Model
    , noop : AppMsg
    , onMdl : Material.Msg AppMsg -> AppMsg
    }


type alias ScheduleViewModel =
    { displayText : String
    , isOverDue : Bool
    , startEditingMsg : AppMsg
    }


type alias TodoKeyedItemView =
    ( String, Html AppMsg )


keyedItem : TodoViewModel -> TodoKeyedItemView
keyedItem vm =
    ( vm.key, item vm )


item : TodoViewModel -> Html AppMsg
item vm =
    div
        [ classList
            [ "todo-item focusable-list-item collection-item" => True
            , "selected" => vm.isSelected
            , "can-be-focused" => vm.canBeFocused
            ]
        , X.Html.onFocusIn vm.onFocusIn
        , tabindex vm.tabindexAV
        , onKeyDown vm.onKeyDownMsg
        , attribute "data-key" vm.key
        ]
        [ div
            [ class "display-text-container layout horizontal"
            , onMouseDown vm.startEditingMsg
            ]
            [ div [ class "self-start" ] [ doneIconButton vm ]
            , div [ class "display-text" ] (parseDisplayText vm)
            ]
        , div
            [ class "layout horizontal end-justified"
            ]
            [ div [ style [ "margin" => "0 8px" ] ] [ editScheduleButton vm ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-context-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showContextDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.contextDisplayName ]
                ]
            , div [ style [ "padding" => "0 8px" ], class "layout horizontal center-center" ]
                [ a
                    [ id ("edit-project-button-" ++ vm.key)
                    , style [ "color" => "black", "min-width" => "3rem" ]
                    , onClick vm.showProjectDropDownMsg
                    , tabindex vm.tabindexAV
                    ]
                    [ text vm.projectDisplayName ]
                ]
            ]
        ]


parseDisplayText vm =
    --Markdown.toHtml Nothing displayText
    let
        createLink url =
            a
                [ href url
                , target "_blank"
                , onMouseDownStopPropagation Msg.noop
                , tabindex vm.tabindexAV
                ]
                [ url |> RegexHelper.stripUrlPrefix |> String.ellipsis 30 |> String.toLower |> text ]

        linkStrings =
            Regex.find Regex.All RegexHelper.url vm.displayText
                .|> .match
                >> createLink

        nonLinkStrings =
            Regex.split Regex.All RegexHelper.url vm.displayText
                .|> text
    in
        List.interweave nonLinkStrings linkStrings


classListAsClass list =
    list
        |> List.filter Tuple.second
        |> List.map Tuple.first
        |> String.join " "


doneIconButton : TodoViewModel -> Html AppMsg
doneIconButton vm =
    Mat.iconBtn4 vm.onMdl
        "done"
        vm.tabindexAV
        (classListAsClass [ "done-icon" => True, "is-done" => vm.isDone ])
        vm.toggleDoneMsg


editScheduleButton vm =
    div
        [ id ("edit-schedule-button-" ++ vm.key)
        , class "layout horizontal center-center"
        , onClick vm.reminder.startEditingMsg
        ]
        [ div
            [ classList
                [ "overdue" => vm.reminder.isOverDue
                , "reminder-text" => True
                ]
            ]
            [ vm.reminder.displayText |> text ]
        , Mat.iconBtn Msg.OnMdl
            vm.mdl
            [ Mat.tabIndex vm.tabindexAV
            ]
            [ Mat.iconSmall "schedule" ]
        ]


fireCancel =
    Msg.revertExclusiveMode


editTodoTextView : TodoForm -> Html AppMsg
editTodoTextView form =
    let
        todoText =
            form.text

        fireTextChanged =
            TodoMsg.onSetTodoFormText form

        fireToggleDelete =
            Msg.onEntityUpdateMsg (TodoId form.id) Entity.Types.EUA_ToggleDeleted
    in
        div
            [ class "overlay"
            , onClickStopPropagation fireCancel
            , onKeyDownStopPropagation (\_ -> Msg.noop)
            ]
            [ div [ class "modal fixed-center", onClickStopPropagation Msg.noop ]
                [ div [ class "modal-content" ]
                    [ div [ class "input-field", onKeyDownStopPropagation (\_ -> Msg.noop) ]
                        [ textarea
                            [ class "materialize-textarea auto-focus"
                            , defaultValue todoText
                            , onInput fireTextChanged
                            ]
                            []
                        , Html.label [] [ text "Todo" ]
                        ]
                    , defaultOkCancelDeleteButtons fireToggleDelete
                    ]
                ]
            ]


new form =
    div
        [ class "overlay"
        , onClickStopPropagation fireCancel
        , onKeyDownStopPropagation (\_ -> Msg.noop)
        ]
        [ div [ class "modal fixed-center", onClickStopPropagation Msg.noop ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field" ]
                    [ textarea
                        [ class "materialize-textarea auto-focus"
                        , onInput (TodoMsg.onSetTodoFormText form)
                        , form.text |> defaultValue
                        ]
                        []
                    , label [ class "active" ] [ text "New Todo" ]
                    ]
                , defaultOkCancelButtons
                ]
            ]
        ]


editTodoProjectPopupView =
    Todo.View.Menu.project


editTodoContextPopupView =
    Todo.View.Menu.context


editTodoSchedulePopupView form =
    div
        [ class "overlay"
        , onClickStopPropagation Msg.revertExclusiveMode
        , onKeyDownStopPropagation (\_ -> Msg.noop)
        ]
        [ div
            [ id "popup-menu"
            , class "z-depth-4 static"
            , onClickStopPropagation Msg.noop
            ]
            [ div [ class "font-subhead" ] [ text "Select date and time" ]
            , div [ class "input-field" ]
                [ Html.input
                    [ type_ "date"
                    , class "auto-focus"
                    , defaultValue form.date
                    , TodoMsg.onSetTodoFormReminderDate form |> onChange
                    ]
                    []
                , Html.label [ class "active" ] [ "Date" |> text ]
                ]
            , div [ class "input-field" ]
                [ Html.input
                    [ type_ "time"
                    , defaultValue form.time
                    , TodoMsg.onSetTodoFormReminderTime form |> onChange
                    ]
                    []
                , Html.label [ class "active" ] [ "Time" |> text ]
                ]
            , defaultOkCancelButtons
            ]
        ]
