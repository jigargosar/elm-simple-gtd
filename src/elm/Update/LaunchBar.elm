module Update.LaunchBar exposing (..)

import Entity.Types
import LaunchBar.Models exposing (SearchItem(..))
import LaunchBar.Update
import Msg
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.ViewType
import Stores
import Tuple2
import X.Return


map =
    Return.map


update andThenUpdate msg now =
    Return.andThen
        (\m ->
            let
                config =
                    LaunchBar.Update.Config
                        now
                        (Stores.getActiveProjects m)
                        (Stores.getActiveContexts m)
            in
                m.launchBar
                    |> LaunchBar.Update.update config msg
                    |> Tuple2.mapEach
                        (\l -> { m | launchBar = l })
                        (Cmd.map Msg.OnLaunchBarMsg)
        )
        >> X.Return.withMaybe (.launchBar >> .maybeResult)
            (\result ->
                andThenUpdate Msg.OnDeactivateEditingMode
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
