module Todo exposing (..)

import Date
import Date.Distance exposing (defaultConfig)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Maybe.Extra as Maybe
import PouchDB
import Ext.Random as Random
import Random.Pcg as Random exposing (Seed)
import Todo.Internal as Internal exposing (..)
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
import Project exposing (ProjectId)
import Todo.Types exposing (..)


getDeleted =
    Internal.getDeleted


update =
    Internal.updateAll


defaultDueAt =
    Nothing


defaultDeleted =
    False


defaultDone =
    False


getAllTodoContexts =
    [ Session
    , Calender
    , Inbox
    , WaitingFor
    , NextAction
    , Project
    , SomeDayMayBe
    , Reference
    ]


getContextName =
    getTodoContext >> todoContextToName


todoContextToName todoContext =
    case todoContext of
        Session ->
            "Session"

        Inbox ->
            "Inbox"

        SomeDayMayBe ->
            "SomeDayMayBe"

        WaitingFor ->
            "WaitingFor"

        Project ->
            "Project"

        Calender ->
            "Calender"

        NextAction ->
            "NextAction"

        Reference ->
            "Reference"


todoConstructor id rev createdAt modifiedAt done text dueAt deleted context projectId =
    { id = id
    , rev = rev
    , done = done
    , text = text
    , dueAt = dueAt
    , deleted = deleted
    , context = context
    , projectId = projectId
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


todoRecordDecoder =
    D.optional "done" D.bool defaultDone
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "deleted" D.bool defaultDeleted
        >> D.optional "context" contextDecoder Inbox
        >> D.optional "projectId" (D.nullable D.string) Nothing


todoDecoder : Decoder Todo
todoDecoder =
    D.decode todoConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> todoRecordDecoder


contextDecoder : Decoder TodoContext
contextDecoder =
    let
        createContext string =
            getAllTodoContexts
                |> Dict.fromListBy toString
                |> Dict.get string
                ?= Inbox
    in
        D.string |> D.map createContext


copyTodo createdAt todo id =
    { todo | id = id, rev = PouchDB.defaultRevision, createdAt = createdAt, modifiedAt = createdAt }


encodeTodo : Todo -> EncodedTodo
encodeTodo todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "_rev" => E.string (getRev todo)
        , "done" => E.bool (isDone todo)
        , "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (getDeleted todo)
        , "context" => E.string (getTodoContext todo |> toString)
        , "projectId" => (todo |> getProjectId >> Maybe.unwrap E.null E.string)
        , "createdAt" => E.int (todo.createdAt |> round)
        , "modifiedAt" => E.int (todo.modifiedAt |> round)
        ]


todoGenerator createdAt text =
    let
        initWith id =
            todoConstructor
                id
                PouchDB.defaultRevision
                createdAt
                createdAt
                defaultDone
                text
                defaultDueAt
                defaultDeleted
                Inbox
                Nothing
    in
        Random.map initWith Random.idGenerator


copyGenerator createdAt todo =
    Random.mapWithIdGenerator (copyTodo createdAt todo)


getText =
    (.text)


isDone : Model -> Bool
isDone =
    (.done)


getModifiedAt : Model -> Time
getModifiedAt =
    (.modifiedAt)


getId =
    (.id)


getMaybeProjectId : Model -> Maybe ProjectId
getMaybeProjectId =
    (.projectId)


getTodoContext : Model -> TodoContext
getTodoContext =
    (.context)


equalById todo1 todo2 =
    getId todo1 == getId todo2


hasId todoId =
    getId >> equals todoId


isNotDeleted =
    getDeleted >> not


binFilter =
    toAllPassPredicate [ getDeleted ]


filterAllPass =
    toAllPassPredicate >> List.filter


rejectAnyPass =
    toAnyPassPredicate >> List.filterNot


doneFilter =
    toAllPassPredicate [ isNotDeleted, isDone ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


toAnyPassPredicate predicateList =
    (applyList predicateList >> List.any identity)


toVM : Todo -> ViewModel
toVM =
    identity


createdAtInWords : Time -> Todo -> String
createdAtInWords now =
    getCreatedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)


modifiedAtInWords : Time -> Todo -> String
modifiedAtInWords now =
    getModifiedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)
