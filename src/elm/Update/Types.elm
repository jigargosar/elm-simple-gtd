module Update.Types exposing (..)

import Msg exposing (AppMsg)
import Return
import Types exposing (AppModel)


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias AndThenUpdate =
    AppMsg -> ReturnF
