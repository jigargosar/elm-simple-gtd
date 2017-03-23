module DomUpdate exposing (..)

import Dom
import DomT exposing (..)
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

