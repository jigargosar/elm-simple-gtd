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
