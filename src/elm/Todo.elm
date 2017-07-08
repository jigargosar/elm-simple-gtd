module Todo exposing (..)

import Context
import Date
import Document exposing (Revision)
import X.Record exposing (over, set)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Maybe.Extra as Maybe
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List
import Time exposing (Time)
import Project
import Store
import Todo.Schedule
import Types


type alias Text =
    String


type alias Record =
    { done : Bool
    , text : Text
    , schedule : Todo.Schedule.Model
    , projectId : Types.DocId
    , contextId : Types.DocId
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
    | SetContextId Types.DocId
    | SetScheduleFromMaybeTime (Maybe Time)
    | SetContext Context.Model
    | SetProjectId Types.DocId
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
    X.Record.field .done (\s b -> { b | done = s })


text =
    X.Record.field .text (\s b -> { b | text = s })


schedule =
    X.Record.field .schedule (\s b -> { b | schedule = s })


projectId =
    X.Record.field .projectId (\s b -> { b | projectId = s })


contextId =
    X.Record.field .contextId (\s b -> { b | contextId = s })


deleted =
    X.Record.field .deleted (\s b -> { b | deleted = s })


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


isReminderOverdue now model =
    let
        isOverDue =
            getMaybeReminderTime >> Maybe.unwrap False (\time -> time <= now)
    in
        if isActive model then
            isOverDue model
        else
            False


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


todoConstructor id rev createdAt modifiedAt deleted deviceId done text schedule projectId contextId =
    { id = id
    , rev = rev
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deviceId = deviceId
    , deleted = deleted

    --
    , done = done
    , text = text
    , schedule = schedule
    , projectId = projectId
    , contextId = contextId
    }


todoRecordDecoder =
    D.optional "done" D.bool defaultDone
        >> D.required "text" D.string
        >> D.custom Todo.Schedule.decode
        >> D.optional "projectId" D.string defaultProjectId
        >> D.optional "contextId" D.string defaultContextId


decoder : Decoder Model
decoder =
    D.decode todoConstructor
        |> Document.documentFieldsDecoder
        |> todoRecordDecoder


encodeOtherFields todo =
    [ "done" => E.bool (isDone todo)
    , "text" => E.string (getText todo)
    , "projectId" => (todo.projectId |> E.string)
    , "contextId" => (todo.contextId |> E.string)
    , "schedule" => (Todo.Schedule.encode todo.schedule)
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
        Todo.Schedule.unscheduled
        defaultProjectId
        defaultContextId


getText =
    (.text)


isDone : Model -> Bool
isDone =
    (.done)


getContextId =
    .contextId


contextFilter context =
    getContextId >> equals (Document.getId context)


hasProject project =
    getProjectId >> equals (Document.getId project)


isNotDeleted =
    getDeleted >> not


isNotDone =
    isDone >> not


binFilter =
    toAllPassPredicate [ getDeleted ]


doneFilter =
    toAllPassPredicate [ isNotDeleted, isDone ]


hasProjectId : Types.DocId -> Model -> Bool
hasProjectId projectId =
    getProjectId >> equals projectId


projectIdFilter projectId =
    toAllPassPredicate [ hasProjectId projectId, isNotDeleted, isDone >> not ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


toAnyPassPredicate predicateList =
    (applyList predicateList >> List.any identity)


type alias Store =
    Store.Store Record
