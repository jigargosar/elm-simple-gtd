module Update.LaunchBar exposing (..)

import Context
import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import Fuzzy
import GroupDoc.Types exposing (..)
import LaunchBar.Messages
import LaunchBar.Models exposing (LaunchBar, SearchItem(..))
import Model
import Msg exposing (AppMsg(LaunchBarMsg))
import Regex
import Return exposing (andThen)
import Model.ViewType
import Stores
import String.Extra
import Time exposing (Time)
import Tuple2
import Types exposing (AndThenUpdate, ReturnF)
import X.Return
import XMMsg
import LaunchBar.Messages exposing (..)
import Project
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


map =
    Return.map


update :
    AndThenUpdate
    -> LaunchBarMsg
    -> Time
    -> ReturnF
update andThenUpdate msg now =
    andThen
        (\m ->
            let
                config : Config
                config =
                    { now = now
                    , activeProjects = (Stores.getActiveProjects m)
                    , activeContexts = (Stores.getActiveContexts m)
                    }
            in
                m |> Return.singleton >> update2 config andThenUpdate msg
        )



--   >> X.Return.withMaybe (.launchBar >> .maybeResult)
--      (\result ->
--          andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
--              >> case result of
--                  LaunchBar.Models.Selected entity ->
--                      case entity of
--                          SI_Project project ->
--                              map (Model.ViewType.switchToProjectView project)
--
--                          SI_Projects ->
--                              map Model.ViewType.switchToProjectsView
--
--                          SI_Context context ->
--                              map (Model.ViewType.switchToContextView context)
--
--                          SI_Contexts ->
--                              map Model.ViewType.switchToContextsView
--
--                  LaunchBar.Models.Canceled ->
--                      identity
--      )


type alias Config =
    { now : Time
    , activeProjects : List ContextDoc
    , activeContexts : List ProjectDoc
    }


update2 :
    Config
    -> AndThenUpdate
    -> LaunchBarMsg
    -> ReturnF
update2 config andThenUpdate msg =
    case msg of
        NOOP ->
            identity

        OnLBEnter entity ->
            andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus
                >> case entity of
                    SI_Project project ->
                        map (Model.ViewType.switchToProjectView project)

                    SI_Projects ->
                        map Model.ViewType.switchToProjectsView

                    SI_Context context ->
                        map (Model.ViewType.switchToContextView context)

                    SI_Contexts ->
                        map Model.ViewType.switchToContextsView

        OnLBInputChanged form text ->
            andThenUpdate
                (updateInput config text form
                    |> XMLaunchBar
                    >> XMMsg.onSetExclusiveMode
                )

        Open ->
            andThenUpdate (config.now |> LaunchBar.Models.initialModel >> XMLaunchBar >> XMMsg.onSetExclusiveMode)
                >> DomPorts.autoFocusInputRCmd

        OnCancel ->
            andThenUpdate XMMsg.onSetExclusiveModeToNoneAndTryRevertingFocus


type alias LaunchBarF =
    LaunchBar -> LaunchBar


updateInput : Config -> String -> LaunchBarF
updateInput config input form =
    let
        now =
            config.now

        newInput =
            input
                |> if now - form.updatedAt > 1 * Time.second then
                    Regex.replace (Regex.AtMost 1)
                        (Regex.regex ("^" ++ Regex.escape form.input))
                        (\_ -> "")
                   else
                    identity
    in
        updateInputHelp newInput form now
            |> (\form ->
                    { form | searchResults = getFuzzyResults input config }
               )


updateInputHelp input model now =
    { model | input = input }
        |> (\model -> { model | updatedAt = now })


fuzzyMatch needle searchItem =
    let
        --        boil = String.toLower
        boil =
            String.Extra.underscored

        boiledHay =
            searchItem |> LaunchBar.Models.getSearchItemName >> boil

        boiledNeedle =
            boil needle

        match n =
            Fuzzy.match [] [] n
    in
        ( searchItem, match boiledNeedle boiledHay )


getFuzzyResults needle { activeContexts, activeProjects } =
    let
        contexts =
            activeContexts .|> SI_Context

        projects =
            activeProjects .|> SI_Project

        all =
            projects ++ contexts ++ [ SI_Projects, SI_Contexts ]
    in
        all
            .|> fuzzyMatch needle
            |> List.sortBy (Tuple.second >> (.score))
