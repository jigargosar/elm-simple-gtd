module Ext.Cmd exposing (..)

import Task
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


toCmds : (List msg -> msg) -> List msg -> Cmd msg
toCmds onMsgList msgList =
    Task.perform identity (msgList |> onMsgList >> Task.succeed)


toCmd : msg -> Cmd msg
toCmd =
    Task.succeed >> Task.perform identity
