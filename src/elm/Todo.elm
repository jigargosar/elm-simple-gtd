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


isDeleted =
    Internal.getDeleted


update =
    Internal.updateAll


defaultDueAt =
    Nothing


defaultDeleted =
    False


defaultDone =
    False


todoConstructor id rev createdAt modifiedAt done text dueAt deleted projectId contextId =
    { id = id
    , rev = rev
    , dirty = False
    , done = done
    , text = text
    , dueAt = dueAt
    , deleted = deleted
    , projectId = projectId
    , contextId = contextId
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


todoRecordDecoder =
    D.optional "done" D.bool defaultDone
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "deleted" D.bool defaultDeleted
        >> D.optional "projectId" (D.nullable D.string) Nothing
        >> D.optional "contextId" (D.nullable D.string) Nothing


decoder : Decoder Todo
decoder =
    D.decode todoConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> todoRecordDecoder


copyTodo createdAt todo id =
    { todo | id = id, rev = PouchDB.defaultRevision, createdAt = createdAt, modifiedAt = createdAt }


encode : Todo -> EncodedTodo
encode todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "_rev" => E.string (getRev todo)
        , "done" => E.bool (isDone todo)
        , "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (getDeleted todo)
        , "projectId" => (todo |> getProjectId >> Maybe.unwrap E.null E.string)
        , "contextId" => (todo.contextId |> Maybe.unwrap E.null E.string)
        , "createdAt" => E.int (todo.createdAt |> round)
        , "modifiedAt" => E.int (todo.modifiedAt |> round)
        ]


init createdAt text id =
    todoConstructor
        id
        PouchDB.defaultRevision
        createdAt
        createdAt
        defaultDone
        text
        defaultDueAt
        defaultDeleted
        Nothing
        Nothing


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


markDone =
    Internal.update (SetDone True)


getMaybeProjectId : Model -> Maybe ProjectId
getMaybeProjectId =
    (.projectId)


getMaybeContextId =
    .contextId


equalById todo1 todo2 =
    getId todo1 == getId todo2


hasId todoId =
    getId >> equals todoId


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


hasProjectId : ProjectId -> Todo -> Bool
hasProjectId projectId =
    getMaybeProjectId >>? equals projectId >>?= False


projectIdFilter projectId =
    toAllPassPredicate [ hasProjectId projectId, isNotDeleted, isDone >> not ]


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
