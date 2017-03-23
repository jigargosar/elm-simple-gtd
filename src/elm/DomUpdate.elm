module DomUpdate exposing (..)

import Dom
import DomTypes exposing (..)
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Task


focusCmd : Dom.Id -> (DomResult -> msg) -> Cmd msg
focusCmd =
    Dom.focus >> (flip Task.attempt)


focus =
    focusCmd >>> Return.command


update msg =
    Return.singleton
        >> case msg of
            OnResult result ->
                let
                    _ =
                        result |> Result.mapError (Debug.log "Error: Dom")
                in
                    identity

            OnFocus id ->
                identity
