module LaunchBar.Update exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity.Types
import LaunchBar.Messages exposing (LBMsg(..))
import LaunchBar.Models exposing (Config, LBEntity(..), LaunchBar, Result(Canceled, Selected), updateInput)
import Model.ExMode
import Model.ViewType
import Msg
import Return
import Time exposing (Time)
import Types exposing (ReturnF)


map =
    Return.map


update :
    Config
    -> LBMsg
    -> LaunchBar
    -> ( LaunchBar, Cmd LBMsg )
update config msg =
    Return.singleton
        >> case msg of
            OnLBEnter entity ->
                map (\model -> { model | maybeResult = Selected entity |> Just })

            OnLBInputChanged form text ->
                map (updateInput config text)

            OnLBOpen ->
                map (\m -> { m | maybeResult = Nothing })
                    >> DomPorts.autoFocusInputCmd

            OnCancel ->
                map (\m -> { m | maybeResult = Just Canceled })
