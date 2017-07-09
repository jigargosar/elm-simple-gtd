module LaunchBar.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity.Types
import LaunchBar.Types exposing (LBEntity(..), LBMsg(..))
import Model
import Model.ExMode
import Model.ViewType
import Msg
import Return
import Time
import Types exposing (ReturnF)


map =
    Return.map


update :
    (Msg.Msg -> ReturnF)
    -> Time.Time
    -> LBMsg
    -> ReturnF
update andThenUpdate now msg =
    case msg of
        OnLBEnter entity ->
            andThenUpdate Msg.OnDeactivateEditingMode
                >> case entity of
                    LBProject project ->
                        map (Model.ViewType.switchToProjectView project)

                    LBProjects ->
                        map (Model.ViewType.setEntityListViewType Entity.Types.ProjectsView)

                    LBContext context ->
                        map (Model.ViewType.switchToContextView context)

                    LBContexts ->
                        map (Model.ViewType.setEntityListViewType Entity.Types.ContextsView)

        OnLBInputChanged form text ->
            map (Model.ExMode.updateLaunchBarInput now text form)

        OnLBOpen ->
            map (Model.ExMode.activateLaunchBar now) >> DomPorts.autoFocusInputCmd
