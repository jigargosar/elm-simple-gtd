module DomUpdate exposing (..)

import Dom
import DomTypes exposing (..)
import Main.Model exposing (Model)
import Return exposing (Return)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Task
import Function exposing ((>>>))


--focusCmd : Dom.Id -> (DomResult -> msg) -> Cmd msg


focusCmd =
    Dom.focus >> (flip Task.attempt)


type alias UpdateReturnF msg =
    Return msg Model -> Return msg Model


focus : DomId -> (DomResult -> msg) -> UpdateReturnF msg
focus =
    focusCmd >>> Return.command


update : DomMsg -> Model -> ( Model, Cmd DomMsg )
update msg =
    Return.singleton
        >> case msg of
            OnResult result ->
                let
                    _ =
                        result |> Result.mapError (Debug.log "Error: Dom")
                in
                    identity

            Focus id ->
                focus id OnResult
