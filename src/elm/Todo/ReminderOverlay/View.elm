module Todo.ReminderOverlay.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Mat
import Time
import Todo.ReminderOverlay.Model
import Todo.ReminderOverlay.Types
import Toolkit.Operators exposing (..)
import X.Html exposing (onClickStopPropagation)


maybeOverlay config m =
    m.reminderOverlay ?|> reminderOverlayActiveView config


reminderOverlayActiveView config ( activeView, todoDetails ) =
    let
        activeViewShell children =
            let
                onOutsideMouseDown =
                    config.onReminderOverlayAction Todo.ReminderOverlay.Model.Close
            in
            div [ class "notification overlay", onClickStopPropagation onOutsideMouseDown ]
                [ div [ class "fixed-bottom top-shadow static", onClickStopPropagation config.noop ]
                    [ h5
                        [ class "todo-text"
                        , config.onGoToTodoDocIdMsg todoDetails.id |> onClickStopPropagation
                        ]
                        [ text todoDetails.text ]
                    , div [ class "layout horizontal wrap flex-auto-children " ]
                        children
                    ]
                ]
    in
    case activeView of
        Todo.ReminderOverlay.Types.InitialView ->
            let
                vm =
                    { onDismissClicked = config.onReminderOverlayAction Todo.ReminderOverlay.Model.Dismiss
                    , onDoneClicked = config.onReminderOverlayAction Todo.ReminderOverlay.Model.MarkDone
                    , onSnoozeClicked = config.onReminderOverlayAction Todo.ReminderOverlay.Model.ShowSnoozeOptions
                    }
            in
            activeViewShell
                [ Mat.bigIconTextBtn "not_interested" "dismiss" vm.onDismissClicked
                , Mat.bigIconTextBtn "snooze" "snooze" vm.onSnoozeClicked
                , Mat.bigIconTextBtn "done" "done!" vm.onDoneClicked
                ]

        Todo.ReminderOverlay.Types.SnoozeView ->
            let
                msg =
                    Todo.ReminderOverlay.Model.SnoozeTill >> config.onReminderOverlayAction

                vm =
                    { snoozeFor15Min = msg (Todo.ReminderOverlay.Model.SnoozeForMilli (Time.minute * 15))
                    , snoozeFor1Hour = msg (Todo.ReminderOverlay.Model.SnoozeForMilli Time.hour)
                    , snoozeFor3Hours = msg (Todo.ReminderOverlay.Model.SnoozeForMilli (Time.hour * 3))
                    , snoozeTillTomorrow = msg Todo.ReminderOverlay.Model.SnoozeTillTomorrow
                    }
            in
            activeViewShell
                [ Mat.bigIconTextBtn "snooze" "15 min" vm.snoozeFor15Min
                , Mat.bigIconTextBtn "snooze" "1 hour" vm.snoozeFor1Hour
                , Mat.bigIconTextBtn "snooze" "3 hour" vm.snoozeFor3Hours
                , Mat.bigIconTextBtn "snooze" "tomorrow" vm.snoozeTillTomorrow
                ]
