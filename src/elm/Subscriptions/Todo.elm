module Subscriptions.Todo exposing (..)

import Time
import Todo.MainHelpPort exposing (..)
import Todo.Msg exposing (TodoMsg(..))


subscriptions : model -> Sub TodoMsg
subscriptions _ =
    Sub.batch
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * 1) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30) (\_ -> OnProcessPendingNotificationCronTick)
        ]
