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


type alias ModelF =
    Model -> Model


getRev : Model -> Revision
getRev =
    (.rev)


setRev : Revision -> ModelF
setRev rev model =
    { model | rev = rev }


updateRev : (Model -> Revision) -> ModelF
updateRev updater model =
    setRev (updater model) model


getDueAt : Model -> Maybe Time
getDueAt =
    (.dueAt)


setDueAt : Maybe Time -> ModelF
setDueAt dueAt model =
    { model | dueAt = dueAt }


updateDueAt : (Model -> Maybe Time) -> ModelF
updateDueAt updater model =
    setDueAt (updater model) model


getDone : Model -> Bool
getDone =
    (.done)


setDone : Bool -> ModelF
setDone done model =
    { model | done = done }


updateDone : (Model -> Bool) -> ModelF
updateDone updater model =
    setDone (updater model) model


getDeleted : Model -> Bool
getDeleted =
    (.deleted)


setDeleted : Bool -> ModelF
setDeleted deleted model =
    { model | deleted = deleted }


updateDeleted : (Model -> Bool) -> ModelF
updateDeleted updater model =
    setDeleted (updater model) model


getProjectId =
    (.projectId)


setProjectId projectId model =
    { model | projectId = projectId }


updateProjectId updater model =
    setProjectId (updater model) model


getCreatedAt : Model -> Time
getCreatedAt =
    (.createdAt)


setCreatedAt : Time -> ModelF
setCreatedAt createdAt model =
    { model | createdAt = createdAt }


updateCreatedAt : (Model -> Time) -> ModelF
updateCreatedAt updater model =
    setCreatedAt (updater model) model


getModifiedAt : Model -> Time
getModifiedAt =
    (.modifiedAt)


setModifiedAt : Time -> ModelF
setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


updateModifiedAt : (Model -> Time) -> ModelF
updateModifiedAt updater model =
    setModifiedAt (updater model) model


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
                    setProjectId projectId model

                SetContext context ->
                    innerUpdate (SetContextId (context |> Document.getId)) model

                SetProject project ->
                    setProjectId (Document.getId project) model

                ToggleDone ->
                    updateDone (getDone >> not) model

                ToggleDeleted ->
                    updateDeleted (getDeleted >> not) model

                SetTime maybeTime ->
                    { model | dueAt = maybeTime }
    in
        (List.foldl innerUpdate # actions)
            >> setModifiedAt now


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
