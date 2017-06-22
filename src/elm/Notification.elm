port module Notification exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg


port closeNotification : String -> Cmd msg


type alias Response =
    { action : String
    , data : { id : String }
    }


type alias Request =
    { tag : String
    , title : String
    , body : String
    , actions : List { title : String, action : String }
    , data :
        { id : String
        , notificationClickedPort : String
        , skipFocusActionList : List String
        }
    }


type alias TodoNotification =
    { title : String
    , tag : String
    , data : TodoNotificationData
    }


type alias TodoNotificationData =
    { id : String }


type alias TodoNotificationEvent =
    { action : String
    , data : TodoNotificationData
    }
