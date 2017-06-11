module Todo.Msg exposing (..)

import Notification exposing (Response)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type Msg
    = ToggleRunning Todo.Id
    | InitRunning Todo.Id
    | StopRunning
    | TogglePaused
    | RunningTodoNotificationResponse Response
    | GotoRunning
    | UpdateTimeTracker
