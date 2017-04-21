module View.ReminderOverlay exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import ReminderOverlay
import Time
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import WebComponents exposing (..)


showReminderOverlay m =
    case m.reminderOverlay of
        ReminderOverlay.Active activeView todoDetails ->
            reminderOverlayActiveView activeView todoDetails

        ReminderOverlay.None ->
            span [] []


reminderOverlayActiveView activeView todoDetails =
    case activeView of
        ReminderOverlay.InitialView ->
            let
                vm =
                    { onDismissClicked = Msg.ReminderOverlayAction ReminderOverlay.Dismiss
                    , onDoneClicked = Msg.ReminderOverlayAction ReminderOverlay.MarkDone
                    , onSnoozeClicked = Msg.ReminderOverlayAction ReminderOverlay.ShowSnoozeOptions
                    }
            in
                activeViewShell todoDetails
                    [ iconTextButton "notification:do-not-disturb" "dismiss" vm.onDismissClicked
                    , iconTextButton "av:snooze" "snooze" vm.onSnoozeClicked
                    , iconTextButton "done" "done!" vm.onDoneClicked
                    ]

        ReminderOverlay.SnoozeView ->
            let
                msg =
                    ReminderOverlay.SnoozeTill >> Msg.ReminderOverlayAction

                vm =
                    { snoozeFor15Min = msg (ReminderOverlay.SnoozeForMilli (Time.minute * 15))
                    , snoozeFor1Hour = msg (ReminderOverlay.SnoozeForMilli (Time.hour))
                    , snoozeFor3Hours = msg (ReminderOverlay.SnoozeForMilli (Time.hour * 3))
                    , snoozeTillTomorrow = msg (ReminderOverlay.SnoozeTillTomorrow)
                    }
            in
                activeViewShell todoDetails
                    [ iconTextButton "av:snooze" "15 min" vm.snoozeFor15Min
                    , iconTextButton "av:snooze" "1 hour" vm.snoozeFor1Hour
                    , iconTextButton "av:snooze" "3 hour" vm.snoozeFor3Hours
                    , iconTextButton "av:snooze" "tomorrow" vm.snoozeTillTomorrow
                    ]


activeViewShell todoDetails children =
    div [ class "full-view" ]
        [ div [ class "fixed-bottom top-shadow static" ]
            [ div [ class "font-headline" ] [ text todoDetails.text ]
            , div [ class "layout horizontal flex-auto-children" ]
                children
            ]
        ]
