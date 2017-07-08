module LaunchBar.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity
import Entity.Types
import LaunchBar
import Model
import Msg
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time


map =
    Return.map


update :
    (Msg.Msg -> Model.ReturnF)
    -> Time.Time
    -> LaunchBar.Msg
    -> Model.ReturnF
update andThenUpdate now msg =
    case msg of
        LaunchBar.OnLBEnter entity ->
            andThenUpdate Msg.OnDeactivateEditingMode
                >> case entity of
                    LaunchBar.LBProject project ->
                        map (Model.switchToProjectView project)

                    LaunchBar.LBProjects ->
                        map (Model.setEntityListViewType Entity.Types.ProjectsView)

                    LaunchBar.LBContext context ->
                        map (Model.switchToContextView context)

                    LaunchBar.LBContexts ->
                        map (Model.setEntityListViewType Entity.Types.ContextsView)

        LaunchBar.OnLBInputChanged form text ->
            map (Model.updateLaunchBarInput now text form)

        LaunchBar.OnLBOpen ->
            map (Model.activateLaunchBar now) >> DomPorts.autoFocusInputCmd
