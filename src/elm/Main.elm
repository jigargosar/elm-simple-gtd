port module Main exposing (..)

import Dom
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Model as Model exposing (Model)
import Main.Msg exposing (..)
import Main.Routing
import Main.View exposing (appView)
import Navigation exposing (Location)
import Return exposing (Return)
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2


type alias ReturnTA =
    Return Msg Model


type alias ReturnMapper =
    ReturnTA -> ReturnTA


type alias Flags =
    { now : Time, encodedTodoList : EncodedTodoList }


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Main.Routing.delta2hash
        , location2messages = Main.Routing.hash2messages
        , init = init
        , update = update
        , view = appView
        , subscriptions = subscriptions
        }


subscriptions m =
    Sub.batch
        []


init : Flags -> ReturnTA
init { now, encodedTodoList } =
    Model.init now encodedTodoList |> Return.singleton


update : Msg -> Model -> ReturnTA
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            LocationChanged loc ->
                identity

            OnAddTodoClicked focusInputId ->
                Return.map (Model.activateAddNewTodoMode "")
                    >> Return.command (domFocusCmd focusInputId OnDomFocusResult)

            OnNewTodoTextChanged text ->
                Return.map (Model.activateAddNewTodoMode text)

            OnNewTodoBlur ->
                deactivateEditingMode

            OnSaveNewTodoAndContinueAdding now ->
                saveNewTodoAndContinueAdding now

            OnNewTodoKeyUp key ->
                case key of
                    Enter ->
                        Return.command (withNow OnSaveNewTodoAndContinueAdding)

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            OnEditTodoClicked focusInputId todo ->
                Return.map (Model.activateEditTodoMode todo)
                    >> Return.command (domFocusCmd focusInputId OnDomFocusResult)

            OnDomFocusResult result ->
                let
                    _ =
                        result |> Result.mapError (Debug.log "Error: Dom.focus")
                in
                    identity

            OnEditTodoTextChanged text ->
                Return.map (Model.updateEditTodoText text)

            SaveEditingTodoWithNow now ->
                saveEditingTodoWithNow now

            OnEditTodoBlur ->
                saveEditingTodo

            OnEditTodoKeyUp key ->
                case key of
                    Enter ->
                        saveEditingTodo

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            OnInboxFlowAction actionType ->
                Return.map (Model.updateInboxFlowWithActionType actionType)

            OnShowTodoList ->
                Return.map (Model.showTodoList)

            OnProcessInbox ->
                Return.map (Model.startProcessingInbox)

            OnFlowMoveTo listType ->
                onFlowMoveTo listType

            OnFlowMarkDeleted ->
                Return.andThen
                    (Model.deleteTodoInboxFlow
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnTodoMoveToClicked listType todo ->
                moveTodoToListType listType todo

            OnDeleteTodoClicked todoId ->
                Return.andThen
                    (Model.deleteTodo todoId
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnTodoDoneClicked todoId ->
                identity

            MoveTodoToListTypeWithNow listType todo now ->
                moveTodoToListTypeWithNow now listType todo

            MoveFlowTodoToListTypeWithNow listType now ->
                moveFlowTodoToListTypeWithNow now listType



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity


domFocusCmd id msg =
    Task.attempt msg (Dom.focus id)


onFlowMoveTo listType =
    Return.command (withNow (MoveFlowTodoToListTypeWithNow listType))


moveFlowTodoToListTypeWithNow now listType =
    Return.andThen
        (Model.moveInboxProcessingTodoToListType now listType
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


moveTodoToListType listType todo =
    Return.command (withNow (MoveTodoToListTypeWithNow listType todo))


moveTodoToListTypeWithNow now listType todo =
    Return.andThen
        (Model.moveTodoToListType now listType todo
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


saveEditingTodo =
    Return.command (withNow SaveEditingTodoWithNow)


saveEditingTodoWithNow now =
    Return.andThen
        (Model.saveEditingTodoAndDeactivateEditTodoMode now
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


withNow : (Time -> Msg) -> Cmd Msg
withNow msg =
    Task.perform msg Time.now


saveNewTodoAndContinueAdding now =
    Return.andThen
        (Model.addNewTodoAndContinueAdding now
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none persistTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
