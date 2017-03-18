module TodoStore.Todo
    exposing
        ( TodoId
        , Todo
        , EncodedTodoList
        , generator
        , replaceIfEqualById
        , fromListById
        , hasId
        , markDeleted
        , decodeTodoList
        , setText
        , isTextEmpty
        , isDeleted
        , equalById
        , encodeSingleton
        , getId
        , getText
        )

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import RandomIdGenerator
import Random.Pcg as Random exposing (Seed)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import FunctionalHelpers exposing (..)
import Result.Extra as Result
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


type StuffType
    = Trash
    | SomeDay
    | Reference
    | ProjectPlanningAction
      -- MultiStep
    | DoItNow
      -- less than 2 mins
    | WaitingForListAction
      -- possible follow up frequency?
    | CalenderAction
    | NextAction


type ProcessingState
    = InBasket
    | Pending
    | Done
    | WaitingFor
    | SomeDayMayBe


type alias Todo =
    { id : TodoId
    , rev : String
    , text : String
    , dueAt : Maybe Time
    , deleted : Bool
    }


type alias TodoList =
    List Todo


todoConstructor id rev text dueAt deleted =
    Todo id rev text dueAt deleted


decoder : Decoder Todo
decoder =
    D.decode todoConstructor
        |> D.required "_id" D.string
        |> D.required "_rev" D.string
        |> D.required "text" D.string
        |> D.optional "dueAt" (D.maybe D.float) defaultDueAt
        |> D.optional "deleted" D.bool defaultDeleted


initWithTextAndId text id =
    todoConstructor id defaultRevision text defaultDueAt defaultDeleted


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
        ]


encodeSingleton : Todo -> EncodedTodoList
encodeSingleton =
    encode >> List.singleton


decodeValue =
    D.decodeValue decoder


decodeTodoList : EncodedTodoList -> List Todo
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
