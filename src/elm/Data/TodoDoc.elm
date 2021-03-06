module Data.TodoDoc exposing (..)

import Data.DeviceId exposing (DeviceId)
import Data.Todo.Schedule as Schedule
import Document exposing (..)
import GroupDoc exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List
import Maybe.Extra as Maybe
import Random.Pcg
import Set exposing (Set)
import Store exposing (..)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)


type alias TodoText =
    String


type alias TodoRecord =
    { done : Bool
    , text : TodoText
    , schedule : Schedule.Model
    , projectId : DocId
    , contextId : DocId
    }


type alias TodoDoc =
    Document TodoRecord


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
    | TA_SetSchedule Schedule.Model
    | TA_SnoozeTill Time
    | TA_AutoSnooze Time


type alias TodoStore =
    Store TodoRecord


type alias Text =
    String


type alias Record =
    { done : Bool
    , text : Text
    , schedule : Schedule.Model
    , projectId : DocId
    , contextId : DocId
    }


type alias Model =
    Document Record


type alias ViewModel =
    Model


type alias Encoded =
    E.Value


type alias ModelF =
    Model -> Model


getMaybeDueAt : Model -> Maybe Time
getMaybeDueAt =
    .schedule >> Schedule.getMaybeDueAt


getMaybeReminderTime =
    .schedule >> Schedule.getMaybeReminderTime


isActive =
    isInActive >> not


isInActive =
    anyPass [ Document.isDeleted, isDone ]


getCreatedAt : Model -> Time
getCreatedAt =
    .createdAt


getModifiedAt : Model -> Time
getModifiedAt =
    .modifiedAt


getMaybeTime model =
    getMaybeReminderTime model |> Maybe.orElse (getMaybeDueAt model)


isScheduled model =
    isActive model && (getMaybeTime model |> Maybe.isJust)


done =
    X.Record.fieldLens .done (\s b -> { b | done = s })


text =
    X.Record.fieldLens .text (\s b -> { b | text = s })


schedule =
    X.Record.fieldLens .schedule (\s b -> { b | schedule = s })


projectId =
    X.Record.fieldLens .projectId (\s b -> { b | projectId = s })


contextId =
    X.Record.fieldLens .contextId (\s b -> { b | contextId = s })


deleted =
    X.Record.fieldLens .deleted (\s b -> { b | deleted = s })


updateSchedule fn model =
    over schedule fn model


update : TodoAction -> ModelF
update action =
    case action of
        TA_SetText val ->
            set text val

        TA_SetContextId val ->
            set contextId val

        TA_SetProjectId val ->
            set projectId val

        TA_SetSchedule val ->
            set schedule val

        TA_CopyProjectAndContextId fromTodo ->
            update (TA_SetContextId fromTodo.contextId)
                >> update (TA_SetProjectId fromTodo.projectId)

        TA_SetProject project ->
            Document.getId project |> set projectId

        TA_SetContext context ->
            Document.getId context |> set contextId

        TA_ToggleDone ->
            toggle done

        TA_MarkDone ->
            set done True

        TA_ToggleDeleted ->
            toggle deleted

        TA_SetScheduleFromMaybeTime maybeTime ->
            set schedule (Schedule.fromMaybeTime maybeTime)

        TA_TurnReminderOff ->
            updateSchedule Schedule.turnReminderOff

        TA_SnoozeTill time ->
            updateSchedule (Schedule.snoozeTill time)

        TA_AutoSnooze now ->
            updateSchedule (Schedule.autoSnooze now)


hasReminderChanged ( old, new ) =
    Schedule.hasReminderChanged old.schedule new.schedule


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
        >> D.custom Schedule.decode
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
    , "schedule" => Schedule.encode todo.schedule
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
        Schedule.unscheduled
        defaultProjectId
        defaultContextId


getText =
    .text


isDone : Model -> Bool
isDone =
    .done


getContextId =
    .contextId


getContextGroupDocId =
    getContextId >> GroupDoc.contextIdFromDocId


getProjectId =
    .projectId


getProjectGroupDocId =
    getProjectId >> GroupDoc.projectIdFromDocId


contextFilter context =
    getContextId >> equals (Document.getId context)


getDocIdFromGroupDocType : GroupDocType -> TodoDoc -> DocId
getDocIdFromGroupDocType gdType =
    case gdType of
        ContextGroupDocType ->
            getContextId

        ProjectGroupDocType ->
            getProjectId


getGroupDocId : GroupDocType -> TodoDoc -> GroupDocId
getGroupDocId gdType =
    case gdType of
        ContextGroupDocType ->
            getContextGroupDocId

        ProjectGroupDocType ->
            getProjectGroupDocId


hasGroupDocId : GroupDocId -> TodoDoc -> Bool
hasGroupDocId groupDocId =
    case groupDocId of
        GroupDocId gdType docId ->
            getDocIdFromGroupDocType gdType >> equals docId


hasGroupDocIdInSet : GroupDocType -> Set DocId -> TodoDoc -> Bool
hasGroupDocIdInSet gdType idSet model =
    Set.member (getDocIdFromGroupDocType gdType model) idSet


hasProject project =
    getProjectId >> equals (Document.getId project)


isNotDone =
    isDone >> not


binFilter =
    toAllPassPredicate [ Document.isDeleted ]


doneFilter =
    toAllPassPredicate [ Document.isNotDeleted, isDone ]


hasProjectId : DocId -> Model -> Bool
hasProjectId projectId =
    getProjectId >> equals projectId


projectIdFilter projectId =
    toAllPassPredicate [ hasProjectId projectId, Document.isNotDeleted, isDone >> not ]


toAllPassPredicate predicateList =
    applyList predicateList >> List.all identity


toAnyPassPredicate predicateList =
    applyList predicateList >> List.any identity


storeGenerator : DeviceId -> List Encoded -> Random.Pcg.Generator TodoStore
storeGenerator =
    Store.generator "todo-db" encodeOtherFields decoder
