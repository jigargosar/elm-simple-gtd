module Todo exposing (..)

import Context
import Date
import Date.Distance exposing (defaultConfig)
import Document exposing (Revision)
import Firebase exposing (DeviceId)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Maybe.Extra as Maybe
import Ext.Random as Random
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Result.Extra as Result
import List
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Time exposing (Time)
import Project
import Store
import Todo.Schedule


type alias Text =
    String


type Reminder
    = None
    | At Time


type alias Id =
    Document.Id


defaultReminder =
    None


type alias Record =
    { done : Bool
    , text : Text
    , schedule : Todo.Schedule.Model
    , projectId : Document.Id
    , contextId : Document.Id
    , deletedAt : Time
    }


type alias Model =
    Document.Document Record


type alias ViewModel =
    Model


type alias Encoded =
    E.Value


type UpdateAction
    = SetDone Bool
    | MarkDone
    | SetText Text
    | SetDeleted Bool
    | SetContextId Id
    | SetScheduleFromMaybeTime (Maybe Time)
    | SetContext Context.Model
    | SetProjectId Id
    | CopyProjectAndContextId Model
    | SetProject Project.Model
    | ToggleDone
    | ToggleDeleted
    | TurnReminderOff
    | SetSchedule Todo.Schedule.Model
    | SnoozeTill Time
    | AutoSnooze


type alias ModelF =
    Model -> Model


getMaybeDueAt : Model -> Maybe Time
getMaybeDueAt =
    .schedule >> Todo.Schedule.getMaybeDueAt


getMaybeReminderTime =
    .schedule >> Todo.Schedule.getMaybeReminderTime


getDeleted : Model -> Bool
getDeleted =
    (.deleted)


isDeleted =
    getDeleted


getProjectId =
    (.projectId)


getCreatedAt : Model -> Time
getCreatedAt =
    (.createdAt)


getModifiedAt : Model -> Time
getModifiedAt =
    (.modifiedAt)


getMaybeTime model =
    getMaybeReminderTime model |> Maybe.orElse (getMaybeDueAt model)


update : UpdateAction -> Time -> ModelF
update action now model =
    case action of
        SetDone done ->
            { model | done = done }

        SetDeleted deleted ->
            { model | deleted = deleted, deletedAt = now }

        SetText text ->
            { model | text = text }

        SetContextId contextId ->
            { model | contextId = contextId }

        SetProjectId projectId ->
            { model | projectId = projectId }

        CopyProjectAndContextId fromTodo ->
            model
                |> update (SetContextId fromTodo.contextId) now
                >> update (SetProjectId fromTodo.projectId) now

        SetContext context ->
            update (SetContextId (Document.getId context)) now model

        SetProject project ->
            update (SetProjectId (Document.getId project)) now model

        ToggleDone ->
            update (SetDone (not model.done)) now model

        MarkDone ->
            update (SetDone True) now model

        ToggleDeleted ->
            update (SetDeleted (not model.deleted)) now model

        SetSchedule schedule ->
            { model | schedule = schedule }

        SetScheduleFromMaybeTime maybeTime ->
            update (SetSchedule (Todo.Schedule.fromMaybeTime maybeTime)) now model

        TurnReminderOff ->
            update (SetSchedule (Todo.Schedule.turnReminderOff model.schedule)) now model

        SnoozeTill time ->
            update (SetSchedule (Todo.Schedule.snoozeTill time model.schedule)) now model

        AutoSnooze ->
            --todo: add update schedule and or lens.
            update (SetSchedule (Todo.Schedule.snoozeTill (now + (Time.minute * 15)) model.schedule)) now model


hasReminderChanged ( old, new ) =
    Todo.Schedule.hasReminderChanged old.schedule new.schedule


isReminderOverdue now =
    getMaybeReminderTime >> Maybe.unwrap False (\time -> time <= now)


isSnoozed todo =
    ( getMaybeReminderTime todo, getMaybeDueAt todo )
        |> maybe2Tuple
        ?|> uncurry notEquals
        ?= False


defaultDueAt =
    Nothing


defaultDeleted =
    False


defaultDeletedAt =
    0


defaultDone =
    False


defaultProjectId =
    ""


defaultContextId =
    ""


todoConstructor id rev createdAt modifiedAt deleted deviceId deletedAt done text dueAt projectId contextId reminder =
    { id = id
    , rev = rev
    , dirty = False
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deviceId = deviceId
    , deleted = deleted

    --
    , deletedAt = deletedAt
    , done = done
    , text = text
    , schedule = dueAtAndReminderToSchedule dueAt reminder
    , projectId = projectId
    , contextId = contextId
    }


dueAtAndReminderToSchedule dueAt reminder =
    dueAt
        ?|> (\dueAt ->
                case reminder of
                    None ->
                        Todo.Schedule.NoReminder dueAt

                    At reminderTime ->
                        Todo.Schedule.WithReminder dueAt reminderTime
            )
        ?= Todo.Schedule.unscheduled


todoRecordDecoder =
    D.optional "deletedAt" D.float defaultDeletedAt
        >> D.optional "done" D.bool defaultDone
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "projectId" D.string defaultProjectId
        >> D.optional "contextId" D.string defaultContextId
        >> D.optional "reminder" reminderDecoder defaultReminder


reminderDecoder : Decoder Reminder
reminderDecoder =
    D.decode (\time -> At time)
        |> D.required "at" D.float


decoder : Decoder Model
decoder =
    D.decode todoConstructor
        |> Document.documentFieldsDecoder
        |> todoRecordDecoder


encodeOtherFields todo =
    [ "done" => E.bool (isDone todo)
    , "text" => E.string (getText todo)
    , "dueAt" => (getMaybeDueAt todo |> Maybe.map E.float ?= E.null)
    , "projectId" => (todo.projectId |> E.string)
    , "contextId" => (todo.contextId |> E.string)
    , "reminder" => (Todo.Schedule.getMaybeReminderTime todo.schedule |> encodeReminder)
    , "deletedAt" => E.float (getDeletedAt todo)
    ]


getDeletedAt todo =
    if getDeleted todo && todo.deletedAt == defaultDeletedAt then
        getModifiedAt todo
    else
        todo.deletedAt


encodeReminder maybeReminderTime =
    maybeReminderTime ?|> (\reminderTime -> E.object [ "at" => E.float reminderTime ]) ?= E.null


init createdAt text deviceId id =
    todoConstructor
        id
        Document.defaultRevision
        createdAt
        createdAt
        defaultDeleted
        deviceId
        defaultDeletedAt
        defaultDone
        text
        defaultDueAt
        defaultProjectId
        defaultContextId
        defaultReminder


getText =
    (.text)


isDone : Model -> Bool
isDone =
    (.done)


getContextId =
    .contextId


contextFilter context =
    getContextId >> equals (Document.getId context)


projectFilter project =
    getProjectId >> equals (Document.getId project)


isNotDeleted =
    getDeleted >> not


isNotDone =
    isDone >> not


filterAllPass =
    toAllPassPredicate >> List.filter


rejectAnyPass =
    toAnyPassPredicate >> List.filterNot


binFilter =
    toAllPassPredicate [ getDeleted ]


doneFilter =
    toAllPassPredicate [ isNotDeleted, isDone ]


hasProjectId : Document.Id -> Model -> Bool
hasProjectId projectId =
    getProjectId >> equals projectId


projectIdFilter projectId =
    toAllPassPredicate [ hasProjectId projectId, isNotDeleted, isDone >> not ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


toAnyPassPredicate predicateList =
    (applyList predicateList >> List.any identity)


createdAtInWords : Time -> Model -> String
createdAtInWords now =
    getCreatedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)


modifiedAtInWords : Time -> Model -> String
modifiedAtInWords now =
    getModifiedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)


type alias Store =
    Store.Store Record
