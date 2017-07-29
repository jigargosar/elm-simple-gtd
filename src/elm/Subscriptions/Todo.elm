module Subscriptions.Todo exposing (..)

import Ports.Todo exposing (..)
import Time
import Todo.Msg exposing (TodoMsg(..))
import Types.AppModel exposing (..)


subscriptions : AppModel -> Sub TodoMsg
subscriptions model =
    Sub.batch
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * 1 * model.config.debugSecondMultiplier) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30 * model.config.debugSecondMultiplier) (\_ -> OnProcessPendingNotificationCronTick)
        ]
