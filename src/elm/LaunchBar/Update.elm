module LaunchBar.Update exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity.Types
import LaunchBar.Messages exposing (LBMsg(..))
import LaunchBar.Models exposing (Config, LBEntity(..), LaunchBar, updateInput)
import Model.ExMode
import Model.ViewType
import Msg
import Return
import Time exposing (Time)
import Types exposing (ReturnF)


map =
    Return.map


update2 :
    Config
    -> LBMsg
    -> LaunchBar
    -> ( LaunchBar, Cmd LBMsg )
update2 config msg =
    Return.singleton
        >> case msg of
            OnLBEnter entity ->
                map (\model -> { model | selectedEntity = Just entity })

            OnLBInputChanged form text ->
                map (updateInput config text)

            OnLBOpen ->
                map (\m -> { m | selectedEntity = Nothing })
                    >> DomPorts.autoFocusInputCmd
