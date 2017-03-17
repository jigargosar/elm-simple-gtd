port module Main exposing (..)

import Json.Encode as E
import Main.Model as Model exposing (Model)
import Main.Msg exposing (..)
import Main.Routing
import Main.View exposing (elmAppView)
import Navigation exposing (Location)
import Return exposing (Return)
import RouteUrl exposing (RouteUrlProgram)
import Time exposing (Time)
import PouchDB
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import TodoCollection.Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
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
        , view = elmAppView
        , subscriptions = subscriptions
        }



--main : Program Flags Model Msg
--main =
--    Navigation.programWithFlags LocationChanged
--        --    TimeTravel.Navigation.programWithFlags LocationChanged
--        { init = init
--        , view = elmAppView
--        , update = update
--        , subscriptions = subscriptions
--        }


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
            LocationChanged loc ->
                identity

            OnAddTodoClicked ->
                Return.map (Model.activateAddNewTodoMode "")

            OnNewTodoTextChanged text ->
                Return.map (Model.activateAddNewTodoMode text)

            OnNewTodoBlur ->
                Return.andThen
                    (Model.addNewTodoAndDeactivateAddNewTodoMode
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnNewTodoEnterPressed ->
                Return.andThen
                    (Model.addNewTodoAndContinueAdding
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnDeleteTodoClicked todoId ->
                Return.andThen
                    (Model.deleteTodo todoId
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnEditTodoClicked todo ->
                Return.map (Model.activateEditTodoMode todo)

            OnEditTodoTextChanged text ->
                Return.map (Model.updateEditTodoText text)

            OnEditTodoBlur ->
                Return.andThen
                    (Model.saveEditingTodoAndDeactivateEditTodoMode
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnEditTodoEnterPressed ->
                Return.andThen
                    (Model.saveEditingTodoAndDeactivateEditTodoMode
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnTrashItYesClicked ->
                identity

            OnYesClicked ->
                identity

            OnNoClicked ->
                identity

            OnBackClicked ->
                identity

            OnInBasketFlowButtonClicked actionType ->
                Return.map (Model.updateInBasketFlowModelWithActionType actionType)

            OnParsedUrl ->
                identity



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity


persistTodoCmdMaybe =
    Maybe.unwrap Cmd.none persistTodoCmd


persistTodoCmd todo =
    PouchDB.pouchDBBulkDocsHelp "todo-db" (Todo.encodeSingleton todo)
