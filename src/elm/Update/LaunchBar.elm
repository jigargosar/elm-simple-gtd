module Update.LaunchBar exposing (..)

import Document.Types exposing (DocId, getDocId)
import DomPorts
import Entity.Types exposing (EntityListViewType)
import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import Fuzzy
import GroupDoc.Types exposing (..)
import LaunchBar.Models exposing (LaunchBar, SearchItem(..))
import Regex
import Return
import String.Extra
import Time exposing (Time)
import LaunchBar.Messages exposing (..)
import Toolkit.Operators exposing (..)


type alias SubModel model =
    model


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias SubAndThenUpdate msg model =
    msg -> SubReturnF msg model


type alias Config msg model =
    { now : Time
    , activeProjects : List ContextDoc
    , activeContexts : List ProjectDoc
    , onComplete : SubReturnF msg model
    , setXMode : ExclusiveMode -> SubReturnF msg model
    , onSwitchView : EntityListViewType -> SubReturnF msg model
    }


update :
    Config msg a
    -> LaunchBarMsg
    -> SubReturnF msg a
update config msg =
    case msg of
        NOOP ->
            identity

        OnLBEnter entity ->
            let
                v =
                    (case entity of
                        SI_Project project ->
                            project |> getDocId >> Entity.Types.ProjectView

                        SI_Projects ->
                            Entity.Types.ProjectsView

                        SI_Context context ->
                            context |> getDocId >> Entity.Types.ContextView

                        SI_Contexts ->
                            Entity.Types.ContextsView
                    )
            in
                config.onComplete
                    >> config.onSwitchView v

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


updateInput : Config msg model -> String -> LaunchBarF
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
        { form | searchResults = getFuzzyResults input config, input = input, updatedAt = now }


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
            |> List.sortBy (Tuple.second >> .score)
