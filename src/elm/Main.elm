port module Main exposing (..)

import Json.Encode as E
import Main.Model as Model exposing (..)
import Main.Msg exposing (..)
import Main.View exposing (elmAppView)
import Navigation exposing (Location)
import Return exposing (Return)
import Time exposing (Time)
import PouchDB
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Function exposing ((>>>), (<<<))
import Maybe.Extra as Maybe
import TodoCollection.Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2


main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChanged
        --    TimeTravel.Navigation.programWithFlags LocationChanged
        { init = Model.initWithFlagsAndLocation >>> Return.singleton
        , view = elmAppView
        , update = update
        , subscriptions =
            \_ ->
                Sub.batch
                    []
        }


update msg =
    Return.singleton
        >> case msg of
            LocationChanged loc ->
                identity

            OnAddTodoClicked ->
                Return.map (Model.activateAddNewTodoMode2 "")

            OnNewTodoTextChanged text ->
                Return.map (Model.activateAddNewTodoMode2 text)

            OnNewTodoBlur ->
                Return.andThen
                    (addNewTodoAndDeactivateAddNewTodoMode
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnNewTodoEnterPressed ->
                Return.andThen
                    (addNewTodoAndContinueAdding
                        >> Tuple2.mapSecond persistTodoCmdMaybe
                    )

            OnDeleteTodoClicked todoId ->
                Return.andThen (deleteTodo todoId
                    >> Tuple2.mapSecond persistTodoCmdMaybe)

            OnEditTodoClicked todo ->
                activateEditTodoMode todo

            OnEditTodoTextChanged text ->
                updateEditTodoText text

            OnEditTodoBlur ->
                saveEditingTodoAndDeactivateEditTodoMode

            OnEditTodoEnterPressed ->
                saveEditingTodoAndDeactivateEditTodoMode



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
