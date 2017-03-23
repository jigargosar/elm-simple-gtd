module DomTypes exposing (..)

import Dom
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Task
import Function exposing ((>>>))


type alias DomResult =
    Result Dom.Error ()


type alias DomId =
    Dom.Id


type DomMsgType
    = OnResult DomResult
    | Focus DomId
