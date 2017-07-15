module Update.LaunchBar exposing (..)

import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import LaunchBar.Messages
import LaunchBar.Models exposing (SearchItem(..))
import LaunchBar.Update
import Model
import Msg exposing (AppMsg(LaunchBarMsg))
import Return
import Model.ViewType
import Stores
import Tuple2
import X.Return
import XMMsg


map =
    Return.map


update andThenUpdate msg now =
    Return.andThen
        (\m ->
            let
                config : LaunchBar.Update.Config AppMsg
                config =
                    { now = now
                    , activeProjects = (Stores.getActiveProjects m)
                    , activeContexts = (Stores.getActiveContexts m)
                    , onCancel = XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                    , onSelect = (\entity -> Model.noop)
                    }
            in
                m.launchBar
                    |> LaunchBar.Update.update config msg
                    |> Return.map
                        (\( msg, l ) -> { m | launchBar = l })
                    |> Return.mapCmd Msg.LaunchBarMsg
        )
        >> X.Return.withMaybe (.launchBar >> .maybeResult)
            (\result ->
                andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                    >> case result of
                        LaunchBar.Models.Selected entity ->
                            case entity of
                                SI_Project project ->
                                    map (Model.ViewType.switchToProjectView project)

                                SI_Projects ->
                                    map Model.ViewType.switchToProjectsView

                                SI_Context context ->
                                    map (Model.ViewType.switchToContextView context)

                                SI_Contexts ->
                                    map Model.ViewType.switchToContextsView

                        LaunchBar.Models.Canceled ->
                            identity
            )


open andThenUpdate =
    andThenUpdate (XMMsg.onSetExclusiveMode XMLaunchBar)
        >> (LaunchBar.Messages.Open |> LaunchBarMsg |> andThenUpdate)
