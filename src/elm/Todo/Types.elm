module Todo.Types exposing (..)

import Document exposing (DocId)
import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import Store exposing (Store)
import Time exposing (Time)


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
    Document.Document TodoRecord


type TodoSchedule
    = NoReminder Time
    | WithReminder Time Time
    | Unscheduled


getTodoText =
    .text


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
