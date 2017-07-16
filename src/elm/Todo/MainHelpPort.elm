port module Todo.MainHelpPort exposing (..)

import Notification


port showTodoReminderNotification : Notification.TodoNotification -> Cmd msg


port notificationClicked : (Notification.TodoNotificationEvent -> msg) -> Sub msg


port showRunningTodoNotification : Notification.Request -> Cmd msg


port onRunningTodoNotificationClicked : (Notification.Response -> msg) -> Sub msg
