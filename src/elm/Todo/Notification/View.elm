module Todo.Notification.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Mat
import X.Html exposing (onClickStopPropagation)
import Model
import Todo.Notification.Model
import Time
import Todo.Notification.Types
import TodoMsg


maybeOverlay m =
    case m.reminderOverlay of
        Todo.Notification.Types.Active activeView todoDetails ->
            reminderOverlayActiveView activeView todoDetails |> Just

        Todo.Notification.Types.None ->
            Nothing


reminderOverlayActiveView activeView todoDetails =
    case activeView of
        Todo.Notification.Types.InitialView ->
            let
                vm =
                    { onDismissClicked = TodoMsg.onReminderOverlayAction Todo.Notification.Model.Dismiss
                    , onDoneClicked = TodoMsg.onReminderOverlayAction Todo.Notification.Model.MarkDone
                    , onSnoozeClicked = TodoMsg.onReminderOverlayAction Todo.Notification.Model.ShowSnoozeOptions
                    }
            in
                activeViewShell todoDetails
                    [ Mat.bigIconTextBtn "not_interested" "dismiss" vm.onDismissClicked
                    , Mat.bigIconTextBtn "snooze" "snooze" vm.onSnoozeClicked
                    , Mat.bigIconTextBtn "done" "done!" vm.onDoneClicked
                    ]

        Todo.Notification.Types.SnoozeView ->
            let
                msg =
                    Todo.Notification.Model.SnoozeTill >> TodoMsg.onReminderOverlayAction

                vm =
                    { snoozeFor15Min = msg (Todo.Notification.Model.SnoozeForMilli (Time.minute * 15))
                    , snoozeFor1Hour = msg (Todo.Notification.Model.SnoozeForMilli (Time.hour))
                    , snoozeFor3Hours = msg (Todo.Notification.Model.SnoozeForMilli (Time.hour * 3))
                    , snoozeTillTomorrow = msg (Todo.Notification.Model.SnoozeTillTomorrow)
                    }
            in
                activeViewShell todoDetails
                    [ Mat.bigIconTextBtn "snooze" "15 min" vm.snoozeFor15Min
                    , Mat.bigIconTextBtn "snooze" "1 hour" vm.snoozeFor1Hour
                    , Mat.bigIconTextBtn "snooze" "3 hour" vm.snoozeFor3Hours
                    , Mat.bigIconTextBtn "snooze" "tomorrow" vm.snoozeTillTomorrow
                    ]


activeViewShell todoDetails children =
    let
        onOutsideMouseDown =
            TodoMsg.onReminderOverlayAction Todo.Notification.Model.Close
    in
        div [ class "notification overlay", onClickStopPropagation onOutsideMouseDown ]
            [ div [ class "fixed-bottom top-shadow static", onClickStopPropagation Model.noop ]
                [ h5 [] [ text todoDetails.text ]
                , div [ class "layout horizontal wrap flex-auto-children " ]
                    children
                ]
            ]
