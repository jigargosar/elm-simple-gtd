module Task.Notification.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import X.Html exposing (onClickStopPropagation)
import Model
import Task.Notification.Model
import Time
import WebComponents exposing (..)


maybeOverlay m =
    case m.reminderOverlay of
        Task.Notification.Model.Active activeView todoDetails ->
            reminderOverlayActiveView activeView todoDetails |> Just

        Task.Notification.Model.None ->
            Nothing


reminderOverlayActiveView activeView todoDetails =
    case activeView of
        Task.Notification.Model.InitialView ->
            let
                vm =
                    { onDismissClicked = Model.ReminderOverlayAction Task.Notification.Model.Dismiss
                    , onDoneClicked = Model.ReminderOverlayAction Task.Notification.Model.MarkDone
                    , onSnoozeClicked = Model.ReminderOverlayAction Task.Notification.Model.ShowSnoozeOptions
                    }
            in
                activeViewShell todoDetails
                    [ iconTextButton "notification:do-not-disturb" "dismiss" vm.onDismissClicked
                    , iconTextButton "av:snooze" "snooze" vm.onSnoozeClicked
                    , iconTextButton "done" "done!" vm.onDoneClicked
                    ]

        Task.Notification.Model.SnoozeView ->
            let
                msg =
                    Task.Notification.Model.SnoozeTill >> Model.ReminderOverlayAction

                vm =
                    { snoozeFor15Min = msg (Task.Notification.Model.SnoozeForMilli (Time.minute * 15))
                    , snoozeFor1Hour = msg (Task.Notification.Model.SnoozeForMilli (Time.hour))
                    , snoozeFor3Hours = msg (Task.Notification.Model.SnoozeForMilli (Time.hour * 3))
                    , snoozeTillTomorrow = msg (Task.Notification.Model.SnoozeTillTomorrow)
                    }
            in
                activeViewShell todoDetails
                    [ iconTextButton "av:snooze" "15 min" vm.snoozeFor15Min
                    , iconTextButton "av:snooze" "1 hour" vm.snoozeFor1Hour
                    , iconTextButton "av:snooze" "3 hour" vm.snoozeFor3Hours
                    , iconTextButton "av:snooze" "tomorrow" vm.snoozeTillTomorrow
                    ]


activeViewShell todoDetails children =
    let
        onOutsideMouseDown =
            Model.ReminderOverlayAction Task.Notification.Model.Close
    in
        div [ class "full-view fixed-top", onClickStopPropagation onOutsideMouseDown ]
            [ div [ class "fixed-bottom top-shadow static" ]
                [ div [ class "font-headline" ] [ text todoDetails.text ]
                , div [ class "layout horizontal flex-auto-children" ]
                    children
                ]
            ]
