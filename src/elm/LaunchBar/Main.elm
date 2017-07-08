module LaunchBar.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import Entity
import Entity.Types
import LaunchBar
import LaunchBar.Types exposing (LBEntity(..), LBMsg(..))
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
    -> LBMsg
    -> Model.ReturnF
update andThenUpdate now msg =
    case msg of
        OnLBEnter entity ->
            andThenUpdate Msg.OnDeactivateEditingMode
                >> case entity of
                    LBProject project ->
                        map (Model.switchToProjectView project)

                    LBProjects ->
                        map (Model.setEntityListViewType Entity.Types.ProjectsView)

                    LBContext context ->
                        map (Model.switchToContextView context)

                    LBContexts ->
                        map (Model.setEntityListViewType Entity.Types.ContextsView)

        OnLBInputChanged form text ->
            map (Model.updateLaunchBarInput now text form)

        OnLBOpen ->
            map (Model.activateLaunchBar now) >> DomPorts.autoFocusInputCmd
