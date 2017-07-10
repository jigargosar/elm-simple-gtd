module Todo.Types exposing (..)

import Document.Types exposing (DocId)
import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import Store.Types exposing (Store)
import Time exposing (Time)


type alias TodoText =
    String


type alias Record =
    { done : Bool
    , text : TodoText
    , schedule : TodoSchedule
    , projectId : DocId
    , contextId : DocId
    }


type alias TodoDoc =
    Document.Types.Document Record


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
    Store Record