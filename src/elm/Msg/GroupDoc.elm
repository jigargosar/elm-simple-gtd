module Msg.GroupDoc exposing (..)

import GroupDoc.FormTypes exposing (GroupDocForm)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type GroupDocMsg
    = OnSaveGroupDocForm GroupDocForm
