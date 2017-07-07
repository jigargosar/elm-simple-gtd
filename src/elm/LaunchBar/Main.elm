module LaunchBar.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity
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
        LaunchBar.OnEnter entity ->
            andThenUpdate Msg.OnDeactivateEditingMode
                >> case entity of
                    LaunchBar.Project project ->
                        map (Model.switchToProjectView project)

                    LaunchBar.Projects ->
                        map (Model.setEntityListViewType Entity.ProjectsView)

                    LaunchBar.Context context ->
                        map (Model.switchToContextView context)

                    LaunchBar.Contexts ->
                        map (Model.setEntityListViewType Entity.ContextsView)

        LaunchBar.OnInputChanged form text ->
            map (Model.updateLaunchBarInput now text form)

        LaunchBar.Open ->
            map (Model.activateLaunchBar now) >> DomPorts.autoFocusInputCmd
