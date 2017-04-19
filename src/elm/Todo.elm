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


type alias Id =
    String


type alias Text =
    String


type Reminder
    = None
    | At Time



--    | WaitingForResponseTill Time


defaultReminder =
    None


type alias Record =
    { done : Bool
    , text : Text
    , dueAt : Maybe Time
    , projectId : Id
    , contextId : Id
    , reminder : Reminder
    }


type alias Model =
    Document.Document Record


type alias ViewModel =
    Model


type alias Encoded =
    E.Value


type UpdateAction
    = SetDone Bool
    | SetText Text
    | SetDeleted Bool
    | SetContextId Id
    | SetTime (Maybe Time)
    | SetContext Context.Model
    | SetProjectId Id
    | SetProject Project.Project
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
                    { model | done = done }

                SetDeleted deleted ->
                    { model | deleted = deleted }

                SetText text ->
                    { model | text = text }

                SetContextId contextId ->
                    { model | contextId = contextId }

                SetProjectId projectId ->
                    { model | projectId = projectId }

                SetContext context ->
                    innerUpdate (SetContextId (Document.getId context)) model

                SetProject project ->
                    innerUpdate (SetProjectId (Document.getId project)) model

                ToggleDone ->
                    innerUpdate (SetDone (not model.done)) model

                ToggleDeleted ->
                    innerUpdate (SetDeleted (not model.deleted)) model

                SetTime maybeTime ->
                    let
                        reminder =
                            if model.dueAt == maybeTime then
                                model.reminder
                            else
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


isReminderActive =
    .reminder >> equals None >> not


maybeTimeToReminder maybeTime =
    maybeTime ?|> At ?= None


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


todoConstructor id rev createdAt modifiedAt deleted done text dueAt projectId contextId reminder =
    { id = id
    , rev = rev
    , dirty = False
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    , deleted = deleted

    --
    , done = done
    , text = text
    , dueAt = dueAt
    , projectId = projectId
    , contextId = contextId
    , reminder = reminder
    }


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


copyTodo createdAt todo id =
    { todo | id = id, rev = Document.defaultRevision, createdAt = createdAt, modifiedAt = createdAt }


encodeOtherFields todo =
    [ "done" => E.bool (isDone todo)
    , "text" => E.string (getText todo)
    , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
    , "projectId" => (todo.projectId |> E.string)
    , "contextId" => (todo.contextId |> E.string)
    , "reminder" => encodeReminder todo.reminder
    ]


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


hasProjectId : Id -> Model -> Bool
hasProjectId projectId =
    getProjectId >> equals projectId


projectIdFilter projectId =
    toAllPassPredicate [ hasProjectId projectId, isNotDeleted, isDone >> not ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


toAnyPassPredicate predicateList =
    (applyList predicateList >> List.any identity)


toVM : Model -> ViewModel
toVM =
    identity


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


storeGenerator : List Encoded -> Random.Generator Store
storeGenerator =
    Store.generator "todo-db" encodeOtherFields decoder


type alias Store =
    Store.Store Record
