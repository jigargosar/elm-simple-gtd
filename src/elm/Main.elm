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

            OnNewTodoKeyUp key ->
                case key of
                    Enter ->
                        saveNewTodo

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            OnDeleteTodoClicked todoId ->
                let
                    _ =
                        Debug.log "todoId" (todoId)
                in
                    Return.andThen
                        (Model.deleteTodo todoId
                            >> Tuple2.mapSecond persistMaybeTodoCmd
                        )

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

            OnFlowTrashItClicked ->
                identity

            OnYesClicked ->
                identity

            OnNoClicked ->
                identity

            OnBackClicked ->
                identity

            OnInBasketFlowAction actionType ->
                Return.map (Model.updateInBasketFlowWithActionType actionType)

            OnShowTodoList ->
                Return.map (Model.showTodoList)

            OnProcessInBasket ->
                Return.map (Model.startProcessingInBasket)

            OnFlowMoveToUnder2mList ->
                Return.andThen
                    (Model.moveInBasketProcessingTodoToUnder2mList
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnFlowMoveToSomeDayMaybe ->
                Return.andThen
                    (Model.moveInBasketProcessingTodoToUnder2mList
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnFlowMoveTo listType ->
                Return.andThen
                    (Model.moveInBasketProcessingTodoToListType listType
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnFlowMarkDeleted ->
                Return.andThen
                    (Model.deleteTodoInBasketFlow
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )

            OnTodoMoveToClicked listType todo->
                Return.andThen
                    (Model.todoToListType listType todo
                        >> Tuple2.mapSecond persistMaybeTodoCmd
                    )



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity


domFocusCmd id msg =
    Task.attempt msg (Dom.focus id)


saveEditingTodo =
    Return.andThen
        (Model.saveEditingTodoAndDeactivateEditTodoMode
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


saveNewTodo =
    Return.andThen
        (Model.addNewTodoAndContinueAdding
            >> Tuple2.mapSecond persistMaybeTodoCmd
        )


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)


persistMaybeTodoCmd =
    Maybe.unwrap Cmd.none persistTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
