module Todo exposing (..)

import Date
import Date.Distance exposing (defaultConfig)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import PouchDB
import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import FunctionExtra exposing (..)
import Result.Extra as Result
import List
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Time exposing (Time)


type alias TodoId =
    String


type alias TodoText =
    String


type alias EncodedTodoList =
    List EncodedTodo


defaultRevision =
    ""


defaultDueAt =
    Nothing


defaultDeleted =
    False


type TodoGroup
    = Inbox
    | SomeDayMayBe
    | WaitingFor
    | Project
    | Calender
    | NextAction
    | Reference


getAllTodoGroups =
    [ Calender
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


type alias TodoFields =
    { done : Bool
    , text : String
    , dueAt : Maybe Time
    , deleted : Bool
    , listType : TodoGroup
    }


type alias Todo =
    PouchDB.Document (PouchDB.WithTimeStamps TodoFields)


type alias Model =
    Todo


type alias ModelMapper =
    Model -> Model


type alias TodoList =
    List Todo


todoConstructor id rev createdAt modifiedAt done text dueAt deleted listType =
    { id = id
    , rev = rev
    , done = done
    , text = text
    , dueAt = dueAt
    , deleted = deleted
    , listType = listType
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


todoFieldsDecoder =
    D.optional "done" D.bool False
        >> D.required "text" D.string
        >> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        >> D.optional "deleted" D.bool defaultDeleted
        >> D.optional "listType" (D.map stringToListType D.string) Inbox


decoder : Decoder Todo
decoder =
    D.decode todoConstructor
        |> PouchDB.documentFieldsDecoder
        |> PouchDB.timeStampFieldsDecoder
        |> todoFieldsDecoder


listTypeEncodings =
    getAllTodoGroups
        |> Dict.fromListBy toString


stringToListType string =
    listTypeEncodings |> Dict.get string ?= Inbox


initWith : Time -> String -> TodoId -> Todo
initWith createdAt text id =
    todoConstructor id defaultRevision createdAt createdAt False text defaultDueAt defaultDeleted Inbox


type alias EncodedTodo =
    E.Value


encode : Todo -> EncodedTodo
encode todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "_rev" => E.string (getRev todo)
        , "done" => E.bool (isDone todo)
        , "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (isDeleted todo)
        , "listType" => E.string (getGroup todo |> toString)
        , "createdAt" => E.int (todo.createdAt |> round)
        , "modifiedAt" => E.int (todo.modifiedAt |> round)
        ]


encodeSingleton : Todo -> EncodedTodoList
encodeSingleton =
    encode >> List.singleton


decodeValue =
    D.decodeValue decoder


decodeTodoList : EncodedTodoList -> TodoList
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
    Random.map (initWith createdAt text) RandomIdGenerator.idGen


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


getText =
    (.text)


getDueAt =
    (.dueAt)


getRev =
    (.rev)


isDeleted =
    (.deleted)


setText text todo =
    { todo | text = text }


isDone : Model -> Bool
isDone =
    (.done)


setDone : Bool -> ModelMapper
setDone done model =
    { model | done = done }


markDone : ModelMapper
markDone =
    setDone True


updateDone : (Model -> Bool) -> ModelMapper
updateDone updater model =
    setDone (updater model) model


toggleDone : ModelMapper
toggleDone =
    updateDone (isDone >> not)


getCreatedAt : Model -> Time
getCreatedAt =
    (.createdAt)


setCreatedAt : Time -> ModelMapper
setCreatedAt createdAt model =
    { model | createdAt = createdAt }


updateCreatedAt : (Model -> Time) -> ModelMapper
updateCreatedAt updater model =
    setCreatedAt (updater model) model


getModifiedAt : Model -> Time
getModifiedAt =
    (.modifiedAt)


setModifiedAt : Time -> ModelMapper
setModifiedAt modifiedAt model =
    { model | modifiedAt = modifiedAt }


updateModifiedAt : (Model -> Time) -> ModelMapper
updateModifiedAt updater model =
    setModifiedAt (updater model) model


getId =
    (.id)


getGroup : Model -> TodoGroup
getGroup =
    (.listType)


setListType : TodoGroup -> ModelMapper
setListType listType model =
    { model | listType = listType }


updateListType : (Model -> TodoGroup) -> ModelMapper
updateListType updater model =
    setListType (updater model) model


markDeleted : ModelMapper
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


doneFilter =
    toAllPassPredicate [ isNotDeleted, isDone ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


getInboxList =
    List.filter inboxFilter


getFirstInboxTodo =
    List.find inboxFilter


groupedTodoLists__ =
    List.filter isNotDeleted
        >> Dict.groupBy (getGroup >> toString)
        >> (\dict ->
                getAllTodoGroups
                    .|> (\listType ->
                            ( groupToName listType, Dict.get (toString listType) dict ?= [] )
                        )
           )


groupedTodoLists =
    List.filter isNotDeleted
        >> Dict.groupBy (getGroup >> toString)
        >> (\dict ->
                getAllTodoGroups
                    .|> (\listType ->
                            ( listType, Dict.get (toString listType) dict ?= [] )
                        )
           )
