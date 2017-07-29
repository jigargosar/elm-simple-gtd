module Types.Todo exposing (..)

import Store exposing (Store)
import Time exposing (Time)
import Types.Document exposing (..)
import Types.GroupDoc exposing (..)


type alias TodoText =
    String


type alias TodoRecord =
    { done : Bool
    , text : TodoText
    , schedule : TodoSchedule
    , projectId : DocId
    , contextId : DocId
    }


type alias TodoDoc =
    Document TodoRecord


type TodoSchedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled


type TodoAction
    = TA_MarkDone
    | TA_SetText TodoText
    | TA_SetContextId DocId
    | TA_SetScheduleFromMaybeTime (Maybe Time)
    | TA_SetContext ContextDoc
    | TA_SetProjectId DocId
    | TA_CopyProjectAndContextId TodoDoc
    | TA_SetProject ProjectDoc
    | TA_ToggleDone
    | TA_ToggleDeleted
    | TA_TurnReminderOff
    | TA_SetSchedule TodoSchedule
    | TA_SnoozeTill Time
    | TA_AutoSnooze Time


type alias TodoStore =
    Store TodoRecord
