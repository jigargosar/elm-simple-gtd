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


type alias UpdateReturn =
    Return DomMsg Model


type alias UpdateReturnF =
    UpdateReturn -> UpdateReturn


focus : DomId -> (DomResult -> DomMsg) -> UpdateReturnF
focus =
    Dom.focus >> (flip Task.attempt) >>> Return.command


update : DomMsg -> Model -> UpdateReturn
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
