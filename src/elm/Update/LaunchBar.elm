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
import Return exposing (andThen, map)
import Model.ViewType
import Stores
import String.Extra
import Time exposing (Time)
import Tuple2
import Types exposing (AndThenUpdate, AppModel, ReturnF)
import X.Return exposing (returnWith)
import XMMsg
import LaunchBar.Messages exposing (..)
import Project
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type alias ReturnF msg =
    Return.ReturnF msg AppModel


type alias AndThenUpdate msg =
    msg -> ReturnF msg


type alias Config msg =
    { now : Time
    , activeProjects : List ContextDoc
    , activeContexts : List ProjectDoc
    , onComplete : ReturnF msg
    , setXMode : ExclusiveMode -> ReturnF msg
    }


updateWithConfig :
    Config msg
    -> AndThenUpdate msg
    -> LaunchBarMsg
    -> ReturnF msg
updateWithConfig config andThenUpdate msg =
    case msg of
        NOOP ->
            identity

        OnLBEnter entity ->
            config.onComplete
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
            updateInput config text form
                |> XMLaunchBar
                >> config.setXMode

        Open ->
            (config.now
                |> LaunchBar.Models.initialModel
                >> XMLaunchBar
                >> config.setXMode
            )
                >> DomPorts.autoFocusInputRCmd

        OnCancel ->
            config.onComplete


type alias LaunchBarF =
    LaunchBar -> LaunchBar


updateInput : Config msg -> String -> LaunchBarF
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
