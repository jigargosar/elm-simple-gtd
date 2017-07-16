module Update.LaunchBar exposing (..)

import Document.Types exposing (DocId)
import DomPorts
import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import Fuzzy
import GroupDoc.Types exposing (..)
import LaunchBar.Messages
import LaunchBar.Models exposing (LaunchBar, SearchItem(..))
import Regex
import Return exposing (andThen, map)
import Model.ViewType
import Set exposing (Set)
import String.Extra
import Time exposing (Time)
import Tuple2
import X.Return exposing (returnWith)
import LaunchBar.Messages exposing (..)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import ViewType exposing (ViewType)


type alias SubModel a =
    { a | mainViewType : ViewType, selectedEntityIdSet : Set DocId }


type alias ReturnF msg a =
    Return.ReturnF msg (SubModel a)


type alias AndThenUpdate msg a =
    msg -> ReturnF msg a


type alias Config msg a =
    { now : Time
    , activeProjects : List ContextDoc
    , activeContexts : List ProjectDoc
    , onComplete : ReturnF msg a
    , setXMode : ExclusiveMode -> ReturnF msg a
    }


updateWithConfig :
    Config msg a
    -> AndThenUpdate msg a
    -> LaunchBarMsg
    -> ReturnF msg a
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


updateInput : Config msg a -> String -> LaunchBarF
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
