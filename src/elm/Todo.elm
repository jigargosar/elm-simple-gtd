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


type alias EncodedTodoList =
    List EncodedTodo


defaultRevision =
    ""


defaultDueAt =
    Nothing


defaultDeleted =
    False


type Group
    = Inbox
    | SomeDayMayBe
    | WaitingFor
    | Project
    | Calender
    | NextAction
    | Reference


type alias ListType =
    { group : Group, encodedName : String, displayName : String }


getAllListTypes =
    [ Calender
    , Inbox
    , WaitingFor
    , NextAction
    , Project
    , SomeDayMayBe
    , Reference
    ]


getListTypeName =
    getListType >> listTypeToName


listTypeToName listType =
    case listType of
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


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


type alias TodoFields =
    { text : String
    , dueAt : Maybe Time
    , deleted : Bool
    , listType : Group
    }


type alias Todo =
    PouchDB.Document (PouchDB.WithTimeStamps TodoFields)


type alias Model =
    Todo


type alias ModelMapper =
    Model -> Model


type alias TodoList =
    List Todo


todoConstructor : PouchDB.Id -> PouchDB.Revision -> Time -> Time -> String -> Maybe Time -> Bool -> Group -> Todo
todoConstructor id rev createdAt modifiedAt text dueAt deleted listType =
    { id = id
    , rev = rev
    , text = text
    , dueAt = dueAt
    , deleted = deleted
    , listType = listType
    , createdAt = createdAt
    , modifiedAt = modifiedAt
    }


todoFieldsDecoder =
    D.required "text" D.string
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
    getAllListTypes
        |> Dict.fromListBy toString


stringToListType string =
    listTypeEncodings |> Dict.get string ?= Inbox


initWith : Time -> String -> TodoId -> Todo
initWith createdAt text id =
    todoConstructor id defaultRevision createdAt createdAt text defaultDueAt defaultDeleted Inbox


type alias EncodedTodo =
    E.Value


encode : Todo -> EncodedTodo
encode todo =
    E.object
        [ "_id" => E.string (getId todo)
        , "_rev" => E.string (getRev todo)
        , "text" => E.string (getText todo)
        , "dueAt" => (getDueAt todo |> Maybe.map E.float ?= E.null)
        , "deleted" => E.bool (isDeleted todo)
        , "listType" => E.string (getListType todo |> toString)
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
    .createdAt
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


getListType : Model -> Group
getListType =
    (.listType)


setListType : Group -> ModelMapper
setListType listType model =
    { model | listType = listType }


updateListType : (Model -> Group) -> ModelMapper
updateListType updater model =
    setListType (updater model) model


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
    toAllPassPredicate [ isNotDeleted, getListType >> equals Inbox ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


getInboxList =
    List.filter inboxFilter


getFirstInboxTodo =
    List.find inboxFilter


todoListsByType =
    List.filter isNotDeleted
        >> Dict.groupBy (getListType >> toString)
        >> (\dict ->
                getAllListTypes
                    .|> (\listType ->
                            ( listTypeToName listType, Dict.get (toString listType) dict ?= [] )
                        )
           )


todoListsByType2 =
    List.filter isNotDeleted
        >> Dict.groupBy (getListType >> toString)
        >> (\dict ->
                getAllListTypes
                    .|> (\listType ->
                            ( listType, Dict.get (toString listType) dict ?= [] )
                        )
           )
