module Todo.Notification.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Mat
import Time
import Todo.Notification.Model
import Todo.Notification.Types
import Toolkit.Operators exposing (..)
import X.Html exposing (onClickStopPropagation)


maybeOverlay config m =
    m.reminderOverlay ?|> reminderOverlayActiveView config


reminderOverlayActiveView config ( activeView, todoDetails ) =
    let
        activeViewShell children =
            let
                onOutsideMouseDown =
                    config.onReminderOverlayAction Todo.Notification.Model.Close
            in
            div [ class "notification overlay", onClickStopPropagation onOutsideMouseDown ]
                [ div [ class "fixed-bottom top-shadow static", onClickStopPropagation config.noop ]
                    [ h5 [] [ text todoDetails.text ]
                    , div [ class "layout horizontal wrap flex-auto-children " ]
                        children
                    ]
                ]
    in
    case activeView of
        Todo.Notification.Types.InitialView ->
            let
                vm =
                    { onDismissClicked = config.onReminderOverlayAction Todo.Notification.Model.Dismiss
                    , onDoneClicked = config.onReminderOverlayAction Todo.Notification.Model.MarkDone
                    , onSnoozeClicked = config.onReminderOverlayAction Todo.Notification.Model.ShowSnoozeOptions
                    }
            in
            activeViewShell
                [ Mat.bigIconTextBtn "not_interested" "dismiss" vm.onDismissClicked
                , Mat.bigIconTextBtn "snooze" "snooze" vm.onSnoozeClicked
                , Mat.bigIconTextBtn "done" "done!" vm.onDoneClicked
                ]

        Todo.Notification.Types.SnoozeView ->
            let
                msg =
                    Todo.Notification.Model.SnoozeTill >> config.onReminderOverlayAction

                vm =
                    { snoozeFor15Min = msg (Todo.Notification.Model.SnoozeForMilli (Time.minute * 15))
                    , snoozeFor1Hour = msg (Todo.Notification.Model.SnoozeForMilli Time.hour)
                    , snoozeFor3Hours = msg (Todo.Notification.Model.SnoozeForMilli (Time.hour * 3))
                    , snoozeTillTomorrow = msg Todo.Notification.Model.SnoozeTillTomorrow
                    }
            in
            activeViewShell
                [ Mat.bigIconTextBtn "snooze" "15 min" vm.snoozeFor15Min
                , Mat.bigIconTextBtn "snooze" "1 hour" vm.snoozeFor1Hour
                , Mat.bigIconTextBtn "snooze" "3 hour" vm.snoozeFor3Hours
                , Mat.bigIconTextBtn "snooze" "tomorrow" vm.snoozeTillTomorrow
                ]
