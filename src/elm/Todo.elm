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


type alias Record =
    { done : Bool
    , text : Text
    , dueAt : Maybe Time
    , projectId : Id
    , contextId : Id
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


getProjectId =
    (.projectId)


getCreatedAt : Model -> Time
getCreatedAt =
    (.createdAt)


getModifiedAt : Model -> Time
getModifiedAt =
    (.modifiedAt)


getTime model =
    model.dueAt ?= model.createdAt


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
                    { model | dueAt = maybeTime }

                TurnReminderOff ->
                    { model | dueAt = Nothing }
    in
        (List.foldl innerUpdate # actions)
            >> (\model -> { model | modifiedAt = now })


isDeleted =
    getDeleted


defaultDueAt =
    Nothing


defaultDeleted =
    False


defaultDone =
    False


todoConstructor id rev createdAt modifiedAt deleted done text dueAt projectId contextId =
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
    }


todoRecordDecoder =
    D.optional "done" D.bool defaultDone
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "projectId" D.string ""
        >> D.optional "contextId" D.string ""


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
    ]


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
        ""
        ""


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
