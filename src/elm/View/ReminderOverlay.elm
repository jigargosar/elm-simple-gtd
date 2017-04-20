module View.ReminderOverlay exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Msg
import ReminderOverlay
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
                    , onDoneClicked = Msg.ReminderOverlayAction ReminderOverlay.Done
                    , onSnoozeClicked = Msg.ReminderOverlayAction ReminderOverlay.Snooze
                    }
            in
                activeViewShell todoDetails
                    [ iconTextButton "notification:do-not-disturb" "dismiss" vm.onDismissClicked
                    , iconTextButton "av:snooze" "snooze" vm.onSnoozeClicked
                    , iconTextButton "done" "done!" vm.onDoneClicked
                    ]

        ReminderOverlay.SnoozeView ->
            span [] []


activeViewShell todoDetails children =
    div [ class "fixed-bottom top-shadow static" ]
        [ div [ class "font-headline" ] [ text todoDetails.text ]
        , div [ class "layout horizontal flex-auto-children" ]
            children
        ]
