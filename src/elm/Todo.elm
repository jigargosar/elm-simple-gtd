module Todo exposing (..)

import Context
import Date
import Date.Distance exposing (defaultConfig)
import Document exposing (Revision)
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


type alias Text =
    String


type Reminder
    = None
    | At Time


type alias Id =
    Document.Id



--    | WaitingForResponseTill Time


defaultReminder =
    None


type alias Record =
    { done : Bool
    , text : Text
    , dueAt : Maybe Time
    , projectId : Document.Id
    , contextId : Document.Id
    , reminder : Reminder
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
    | SetTime (Maybe Time)
    | SetContext Context.Model
    | SetProjectId Id
    | CopyProjectAndContextId Model
    | SetProject Project.Model
    | ToggleDone
    | ToggleDeleted
    | TurnReminderOff
    | SnoozeTill Time


type alias ModelF =
    Model -> Model


getDueAt : Model -> Maybe Time
getDueAt =
    (.dueAt)


getDone : Model -> Bool
getDone =
    (.done)


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
    getMaybeReminderTime model |> Maybe.orElse (getDueAt model)


update : List UpdateAction -> Time -> ModelF
update actions now =
    let
        innerUpdate action model =
            case action of
                SetDone done ->
                    let
                        reminder =
                            if done then
                                None
                            else
                                model.reminder
                    in
                        { model | done = done, reminder = reminder }

                SetDeleted deleted ->
                    { model | deleted = deleted, deletedAt = now, reminder = None }

                SetText text ->
                    { model | text = text }

                SetContextId contextId ->
                    { model | contextId = contextId }

                SetProjectId projectId ->
                    { model | projectId = projectId }

                CopyProjectAndContextId fromTodo ->
                    model
                        |> innerUpdate (SetContextId fromTodo.contextId)
                        >> innerUpdate (SetProjectId fromTodo.projectId)

                SetContext context ->
                    innerUpdate (SetContextId (Document.getId context)) model

                SetProject project ->
                    innerUpdate (SetProjectId (Document.getId project)) model

                ToggleDone ->
                    innerUpdate (SetDone (not model.done)) model

                MarkDone ->
                    innerUpdate (SetDone True) model

                ToggleDeleted ->
                    innerUpdate (SetDeleted (not model.deleted)) model

                SetTime maybeTime ->
                    let
                        reminder =
                            maybeTimeToReminder maybeTime
                    in
                        { model | dueAt = maybeTime, reminder = reminder }

                TurnReminderOff ->
                    { model | reminder = None }

                SnoozeTill time ->
                    { model | reminder = At time }
    in
        (List.foldl innerUpdate # actions)
            >> (\model -> { model | modifiedAt = now })


hasReminderChanged ( old, new ) =
    old.reminder /= new.reminder


getMaybeReminderTime model =
    if Maybe.isNothing model.dueAt then
        Nothing
    else
        case model.reminder of
            None ->
                Nothing

            At time ->
                Just time


isReminderOverdue now =
    getMaybeReminderTime >> Maybe.unwrap False (\time -> time <= now)


isSnoozed todo =
    ( getMaybeReminderTime todo, getDueAt todo )
        |> maybe2Tuple
        ?|> uncurry notEquals
        ?= False


maybeTimeToReminder maybeTime =
    maybeTime ?|> At ?= None


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


todoConstructor id rev createdAt modifiedAt deleted deletedAt done text dueAt projectId contextId reminder =
    { id = id
    , rev = rev
    , dirty = False
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = deleted

    --
    , deletedAt = deletedAt
    , done = done
    , text = text
    , dueAt = dueAt
    , projectId = projectId
    , contextId = contextId
    , reminder = reminder
    }


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
    , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
    , "projectId" => (todo.projectId |> E.string)
    , "contextId" => (todo.contextId |> E.string)
    , "reminder" => encodeReminder todo.reminder
    , "deletedAt" => E.float (getDeletedAt todo)
    ]


getDeletedAt todo =
    if getDeleted todo && todo.deletedAt == defaultDeletedAt then
        getModifiedAt todo
    else
        todo.deletedAt


encodeReminder reminder =
    case reminder of
        None ->
            E.null

        At time ->
            E.object [ "at" => E.float time ]


init createdAt text id =
    todoConstructor
        id
        Document.defaultRevision
        createdAt
        createdAt
        defaultDeleted
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


isNotDeleted =
    getDeleted >> not


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
