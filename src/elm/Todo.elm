module Todo exposing (..)

import Context
import Date
import Date.Distance exposing (defaultConfig)
import Document exposing (Revision)
import Ext.Record exposing (over, set)
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
    }


type alias Model =
    Document.Document Record


type alias ViewModel =
    Model


type alias Encoded =
    E.Value


type UpdateAction
    = MarkDone
    | SetText Text
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
    | AutoSnooze Time


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


isActive =
    isInActive >> not


isInActive =
    anyPass [ isDeleted, isDone ]


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


done =
    Ext.Record.init .done (\s b -> { b | done = s })


text =
    Ext.Record.init .text (\s b -> { b | text = s })


schedule =
    Ext.Record.init .schedule (\s b -> { b | schedule = s })


projectId =
    Ext.Record.init .projectId (\s b -> { b | projectId = s })


contextId =
    Ext.Record.init .contextId (\s b -> { b | contextId = s })


deleted =
    Ext.Record.init .deleted (\s b -> { b | deleted = s })


updateSchedule fn model =
    over schedule fn model


update : UpdateAction -> ModelF
update action =
    case action of
        SetText val ->
            set text val

        SetContextId val ->
            set contextId val

        SetProjectId val ->
            set projectId val

        SetSchedule val ->
            set schedule val

        CopyProjectAndContextId fromTodo ->
            update (SetContextId fromTodo.contextId)
                >> update (SetProjectId fromTodo.projectId)

        SetProject project ->
            Document.getId project |> set projectId

        SetContext context ->
            Document.getId context |> set contextId

        ToggleDone ->
            over done not

        MarkDone ->
            set done True

        ToggleDeleted ->
            over deleted not

        SetScheduleFromMaybeTime maybeTime ->
            set schedule (Todo.Schedule.fromMaybeTime maybeTime)

        TurnReminderOff ->
            updateSchedule Todo.Schedule.turnReminderOff

        SnoozeTill time ->
            updateSchedule (Todo.Schedule.snoozeTill time)

        AutoSnooze now ->
            updateSchedule (Todo.Schedule.autoSnooze now)


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


defaultDone =
    False


defaultProjectId =
    ""


defaultContextId =
    ""


todoConstructor id rev createdAt modifiedAt deleted deviceId done text dueAt projectId contextId reminder =
    { id = id
    , rev = rev
    , dirty = False
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deviceId = deviceId
    , deleted = deleted

    --
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
    D.optional "done" D.bool defaultDone
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
    ]


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
