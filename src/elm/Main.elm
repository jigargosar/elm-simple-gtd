port module Main exposing (..)

import Json.Encode as E
import Main.Model as Model exposing (Model)
import Main.Msg exposing (..)
import Main.View exposing (elmAppView)
import Navigation exposing (Location)
import Return exposing (Return)
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


main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChanged
        --    TimeTravel.Navigation.programWithFlags LocationChanged
        { init = init
        , view = elmAppView
        , update = update
        , subscriptions =
            \_ ->
                Sub.batch
                    []
        }


init : Flags -> Location -> ReturnTA
init { now, encodedTodoList } location =
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

            OnProcessButtonClicked ->
                Return.map Model.activateProcessingMode



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
