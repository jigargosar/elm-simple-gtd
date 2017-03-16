port module Main exposing (..)

import Json.Encode as E
import Main.Model as Model exposing (..)
import Main.Msg exposing (..)
import Main.View exposing (elmAppView)
import Navigation exposing (Location)
import Return exposing (Return)
import Time exposing (Time)
import PouchDB


main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChanged
        --    TimeTravel.Navigation.programWithFlags LocationChanged
        { init = Model.initWithFlagsAndLocation
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
                activateAddNewTodoMode ""

            OnNewTodoTextChanged text ->
                activateAddNewTodoMode text

            OnNewTodoBlur ->
                addNewTodoAndDeactivateAddNewTodoMode

            OnNewTodoEnterPressed ->
                addNewTodoAndContinueAdding

            OnDeleteTodoClicked todoId ->
                deleteTodo todoId

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
