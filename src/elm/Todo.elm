module Todo exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
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


type ListType
    = InBasket
    | Under2m
    | SomeDayMayBe
    | WaitingFor
    | Project
    | Calender
    | NextAction
    | Reference


getAllListTypes =
    [ InBasket
    , Under2m
    , NextAction
    , Calender
    , WaitingFor
    , Project
    , SomeDayMayBe
    , Reference
    ]


getListTypeName =
    getListType >> listTypeToName


listTypeToName listType =
    case listType of
        InBasket ->
            "In Basket"

        Under2m ->
            "Under2m"

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


inBasket =
    InBasket


under2m =
    Under2m


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


type alias Todo =
    { id : TodoId
    , rev : String
    , text : String
    , dueAt : Maybe Time
    , deleted : Bool
    , listType : ListType
    }


type alias Model =
    Todo


type alias ModelMapper =
    Model -> Model


type alias TodoList =
    List Todo


todoConstructor id rev text dueAt deleted listType =
    Todo id rev text dueAt deleted listType


decoder : Decoder Todo
decoder =
    D.decode todoConstructor
        |> D.required "_id" D.string
        |> D.required "_rev" D.string
        |> D.required "text" D.string
        |> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        |> D.optional "deleted" D.bool defaultDeleted
        |> D.optional "listType" (D.map stringToListType D.string) InBasket


listTypeEncodings =
    [ InBasket
    , Under2m
    , SomeDayMayBe
    , WaitingFor
    , Project
    , Calender
    , NextAction
    , Reference
    ]
        |> Dict.fromListBy toString


stringToListType string =
    listTypeEncodings |> Dict.get string ?= InBasket


initWithTextAndId text id =
    todoConstructor id defaultRevision text defaultDueAt defaultDeleted InBasket


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


generator text =
    Random.map (initWithTextAndId text) RandomIdGenerator.idGen


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


getId =
    (.id)


getListType : Model -> ListType
getListType =
    (.listType)


setListType : ListType -> ModelMapper
setListType listType model =
    { model | listType = listType }


updateListType : (Model -> ListType) -> ModelMapper
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


inBasketFilter =
    toAllPassPredicate [ isNotDeleted, getListType >> equals InBasket ]


toAllPassPredicate predicateList =
    (applyList predicateList >> List.all identity)


getInBasketList =
    List.filter inBasketFilter


getFirstInBasketTodo =
    List.find inBasketFilter


setContextUnder2m =
    setListType Under2m


groupByType =
    List.filter isNotDeleted >> Dict.groupBy (getListType >> toString)
