module Subscriptions.Todo exposing (..)

import Ports.Todo exposing (..)
import Time
import Todo.Msg exposing (TodoMsg(..))
import Types exposing (AppModel)


subscriptions : AppModel -> Sub TodoMsg
subscriptions model =
    Sub.batch
        [ notificationClicked OnReminderNotificationClicked
        , onRunningTodoNotificationClicked RunningNotificationResponse
        , Time.every (Time.second * model.config.oneSecond) (\_ -> UpdateTimeTracker)
        , Time.every (Time.second * 30) (\_ -> OnProcessPendingNotificationCronTick)
        ]
