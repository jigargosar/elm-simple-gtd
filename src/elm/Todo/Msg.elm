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
    = OnTodoToggleRunning Todo.Id
    | OnTodoInitRunning Todo.Id
    | OnTodoStopRunning
    | OnTodoTogglePaused
    | OnRunningTodoNotificationClicked Response
    | OnGotoRunningTodo
    | OnUpdateTodoTimeTracker
