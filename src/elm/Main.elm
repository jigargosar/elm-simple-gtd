port module Main exposing (..)

import Main.Model as Model exposing (..)
import Main.Msg exposing (..)
import Main.View exposing (elmAppView)
import Navigation
import Return
import Time exposing (Time)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags LocationChanged
        --    TimeTravel.Navigation.programWithFlags LocationChanged
        { init = \{ now } _ -> ( Model.initWithTime now, {- onSignIn () -} Cmd.none )
        , view = elmAppView
        , update = update
        , subscriptions =
            \_ ->
                Sub.batch
                    []
        }


type alias Flags =
    { now : Time }


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

            OnEditTodoClicked todoId ->
                                activateEditTodoMode todoId
--                identity



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity
