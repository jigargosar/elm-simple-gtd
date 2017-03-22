port module Main exposing (..)

import Dom
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Model as Model exposing (Model)
import Main.Msg as Msg exposing (..)
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
                        Return.command (withNowOld OnSaveNewTodoAndContinueAdding)

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
                identity

            --                Return.andThen
            --                    (Model.deleteTodoInboxFlow
            --                        >> Tuple2.mapSecond persistMaybeTodoCmd
            --                    )
            OnTodoMoveToClicked listType todo ->
                --                moveTodoToListType listType todo
                updateTodoWithNow (SetGroup listType) todo

            OnDeleteTodoClicked todoId ->
                --                updateAndPersistMaybeTodo (Model.updateTodoMaybe Todo.markDeleted todoId)
                updateTodoIdWithNow (Msg.Delete) todoId

            OnTodoDoneClicked todoId ->
                updateAndPersistMaybeTodo (Model.updateTodoMaybe Todo.toggleDone todoId)

            MoveTodoToListTypeWithNow listType todo now ->
                moveTodoToListTypeWithNow now listType todo

            MoveFlowTodoToListTypeWithNow listType now ->
                moveFlowTodoToListTypeWithNow now listType

            UpdateTodoWithNow todoAction todoId now ->
                updateAndPersistMaybeTodo (Model.updateTodoWithAction todoAction now todoId)



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity


updateTodoWithNow action todo =
    updateTodoIdWithNow action (Todo.getId todo)


updateTodoIdWithNow action todoId =
    withNow (UpdateTodoWithNow action todoId)


updateAndPersistMaybeTodo updater =
    Return.andThen
        (updater
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


domFocusCmd id msg =
    Task.attempt msg (Dom.focus id)


onFlowMoveTo listType =
    Return.command (withNowOld (MoveFlowTodoToListTypeWithNow listType))


moveFlowTodoToListTypeWithNow now listType =
    Return.andThen
        (Model.moveInboxProcessingTodoToListType now listType
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


moveTodoToListType listType todo =
    Return.command (withNowOld (MoveTodoToListTypeWithNow listType todo))


moveTodoToListTypeWithNow now listType todo =
    Return.andThen
        (Model.moveTodoToListType now listType todo
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


saveEditingTodo =
    Return.command (withNowOld SaveEditingTodoWithNow)


saveEditingTodoWithNow now =
    Return.andThen
        (Model.saveEditingTodoAndDeactivateEditTodoMode now
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


withNowOld : (Time -> Msg) -> Cmd Msg
withNowOld msg =
    Task.perform msg Time.now


withNow : (Time -> Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
withNow msg =
    Task.perform msg Time.now |> Return.command


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
