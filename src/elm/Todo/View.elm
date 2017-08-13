module Todo.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mat
import X.Html exposing (onChange, onClickStopPropagation, onMouseDownStopPropagation)
import X.Keyboard exposing (..)


--editTodoTextView : TodoForm -> Html AppMsg


editTodoTextView config form =
    let
        todoText =
            form.text

        fireTextChanged =
            config.onSetTodoFormText form

        fireToggleDelete =
            config.onToggleDeleted form.id
    in
    div
        [ class "overlay"
        , onClickStopPropagation config.revertExclusiveModeMsg
        , onKeyDownStopPropagation (\_ -> config.noop)
        ]
        [ div [ class "modal fixed-center", onClickStopPropagation config.noop ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field", onKeyDownStopPropagation (\_ -> config.noop) ]
                    [ textarea
                        [ class "materialize-textarea auto-focus"
                        , defaultValue todoText
                        , onInput fireTextChanged
                        ]
                        []
                    , Html.label [] [ text "Todo" ]
                    ]
                , Mat.okCancelDeleteButtons config fireToggleDelete
                ]
            ]
        ]


new config form =
    div
        [ class "overlay"
        , onClickStopPropagation config.revertExclusiveModeMsg
        , onKeyDownStopPropagation (\_ -> config.noop)
        ]
        [ div [ class "modal fixed-center", onClickStopPropagation config.noop ]
            [ div [ class "modal-content" ]
                [ div [ class "input-field" ]
                    [ textarea
                        [ class "materialize-textarea auto-focus"
                        , onInput (config.onSetTodoFormText form)
                        , form.text |> defaultValue
                        ]
                        []
                    , label [] [ text "New Todo" ]
                    ]
                , Mat.okCancelButtons config
                ]
            ]
        ]


editTodoSchedulePopupView config form =
    div
        [ class "overlay"
        , onClickStopPropagation config.revertExclusiveModeMsg
        , onKeyDownStopPropagation (\_ -> config.noop)
        ]
        [ div
            [ id "popup-menu"
            , class "z-depth-4 static"
            , onClickStopPropagation config.noop
            ]
            [ div [ class "font-subhead" ] [ text "Select date and time" ]
            , div [ class "input-field" ]
                [ Html.input
                    [ type_ "date"
                    , class "auto-focus"
                    , defaultValue form.date
                    , config.onSetTodoFormReminderDate form |> onChange
                    ]
                    []
                , Html.label [ class "active" ] [ "Date" |> text ]
                ]
            , div [ class "input-field" ]
                [ Html.input
                    [ type_ "time"
                    , defaultValue form.time
                    , config.onSetTodoFormReminderTime form |> onChange
                    ]
                    []
                , Html.label [ class "active" ] [ "Time" |> text ]
                ]
            , Mat.okCancelButtons config
            ]
        ]
