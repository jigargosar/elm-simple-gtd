module Todo exposing (..)

import Date
import Date.Distance exposing (defaultConfig)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Maybe.Extra as Maybe
import PouchDB
import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Result.Extra as Result
import List
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Time exposing (Time)
import Project exposing (ProjectId)
import TodoModel.Types exposing (..)


defaultRevision =
    ""


defaultDueAt =
    Nothing


defaultDeleted =
    False


getAllTodoGroups =
    [ Session
    , Calender
    , Inbox
    , WaitingFor
    , NextAction
    , Project
    , SomeDayMayBe
    , Reference
    ]


getListTypeName =
    getGroup >> groupToName


groupToName todoGroup =
    case todoGroup of
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


inbox =
    Inbox


someDayMayBe =
    SomeDayMayBe


waitingFor =
    WaitingFor


project =
    Project


calender =
    Calender


nextAction =
    NextAction


reference =
    Reference


todoConstructor id rev createdAt modifiedAt done text dueAt deleted listType projectId =
    { id = id
    , rev = rev
    , done = done
    , text = text
    , dueAt = dueAt
    , deleted = deleted
    , listType = listType
    , projectId = projectId
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


todoRecordDecoder =
    D.optional "done" D.bool False
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "deleted" D.bool defaultDeleted
        >> D.optional "listType" (D.map stringToListType D.string) Inbox
        >> D.optional "projectId" (D.nullable D.string) Nothing


decoder : Decoder TodoModel
decoder =
    D.decode todoConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> todoRecordDecoder


listTypeEncodings =
    getAllTodoGroups
        |> Dict.fromListBy toString


stringToListType string =
    listTypeEncodings |> Dict.get string ?= Inbox


copyTodo createdAt todo id =
    { todo | id = id, rev = defaultRevision, createdAt = createdAt, modifiedAt = createdAt }


encode : TodoModel -> EncodedTodo
encode todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "_rev" => E.string (getRev todo)
        , "done" => E.bool (isDone todo)
        , "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (isDeleted todo)
        , "listType" => E.string (getGroup todo |> toString)
        , "projectId" => (todo |> getProjectId >> Maybe.unwrap E.null E.string)
        , "createdAt" => E.int (todo.createdAt |> round)
        , "modifiedAt" => E.int (todo.modifiedAt |> round)
        ]


encodeSingleton : TodoModel -> EncodedTodoList
encodeSingleton =
    encode >> List.singleton


decodeValue =
    D.decodeValue decoder


decodeTodoList : EncodedTodoList -> TodoListModel
decodeTodoList =
    List.map decodeValue
        >> List.filterMap
            (\result ->
                case result of
                    Ok todo ->
                        Just todo

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding todo"
                        in
                            Nothing
            )


generator createdAt text =
    let
        initWith id =
            todoConstructor
                id
                defaultRevision
                createdAt
                createdAt
                False
                text
                defaultDueAt
                defaultDeleted
                Inbox
                Nothing
    in
        Random.map initWith RandomIdGenerator.idGen


copyGenerator createdAt todo =
    Random.map (copyTodo createdAt todo) RandomIdGenerator.idGen


createdAtInWords : Time -> TodoModel -> String
createdAtInWords now =
    getCreatedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)


modifiedAtInWords : Time -> TodoModel -> String
modifiedAtInWords now =
    getModifiedAt
        >> Date.fromTime
        >> Date.Distance.inWordsWithConfig
            ({ defaultConfig | includeSeconds = True })
            (Date.fromTime now)


getText =
    (.text)


getDueAt =
    (.dueAt)


getRev =
    (.rev)


type alias Model =
    TodoModel


type alias ModelF =
    Model -> Model


isDeleted : Model -> Bool
isDeleted =
    (.deleted)


setDeleted : Bool -> ModelF
setDeleted deleted model =
    { model | deleted = deleted }


updateDeleted : (Model -> Bool) -> ModelF
updateDeleted updater model =
    setDeleted (updater model) model


toggleDeleted : ModelF
toggleDeleted =
    updateDeleted (isDeleted >> not)


setText text todo =
    { todo | text = text }


isDone : Model -> Bool
isDone =
    (.done)


setDone : Bool -> ModelF
setDone done model =
    { model | done = done }


markDone : ModelF
markDone =
    setDone True


updateDone : (Model -> Bool) -> ModelF
updateDone updater model =
    setDone (updater model) model


toggleDone : ModelF
toggleDone =
    updateDone (isDone >> not)


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


getId =
    (.id)


getProjectId : Model -> Maybe ProjectId
getProjectId =
    (.projectId)


setProjectId : Maybe ProjectId -> ModelF
setProjectId projectId model =
    { model | projectId = projectId }


updateProjectId : (Model -> Maybe ProjectId) -> ModelF
updateProjectId updater model =
    setProjectId (updater model) model


getGroup : Model -> TodoGroup
getGroup =
    (.listType)


setListType : TodoGroup -> ModelF
setListType listType model =
    { model | listType = listType }


updateListType : (Model -> TodoGroup) -> ModelF
updateListType updater model =
    setListType (updater model) model


markDeleted : ModelF
markDeleted todo =
    { todo | deleted = True }


equalById todo1 todo2 =
    getId todo1 == getId todo2


isTextEmpty todo =
    getText todo |> String.trim |> String.isEmpty


hasId todoId =
    getId >> equals todoId


fromListById =
    Dict.fromListBy getId


findById id =
    List.find (hasId id)


replaceIfEqualById todo =
    List.replaceIf (equalById todo) todo


rejectMap filter mapper =
    List.filterMap (ifElse (filter >> not) (mapper >> Just) (\_ -> Nothing))


mapAllExceptDeleted =
    rejectMap isDeleted


isNotDeleted =
    isDeleted >> not


inboxFilter =
    toAllPassPredicate [ isNotDeleted, getGroup >> equals Inbox ]


binFilter =
    toAllPassPredicate [ isDeleted ]


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


getInboxList =
    List.filter inboxFilter


getFirstInboxTodo =
    List.find inboxFilter


toVM : TodoModel -> ViewModel
toVM =
    identity
