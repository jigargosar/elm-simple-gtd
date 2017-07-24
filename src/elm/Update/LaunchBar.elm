module Update.LaunchBar exposing (Config, update)

import Document.Types exposing (DocId, getDocId)
import Entity.Types exposing (EntityListViewType)
import ExclusiveMode.Types exposing (ExclusiveMode(XMLaunchBar))
import Fuzzy
import GroupDoc.Types exposing (..)
import LaunchBar.Messages exposing (..)
import LaunchBar.Models exposing (LaunchBarForm, SearchItem(..))
import Model.GroupDocStore
import Regex
import Return
import String.Extra
import Time exposing (Time)
import Toolkit.Helpers exposing (apply2)
import Toolkit.Operators exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias SubAndThenUpdate msg model =
    msg -> SubReturnF msg model


type alias Config msg =
    { now : Time
    , onComplete : msg
    , setXMode : ExclusiveMode -> msg
    , onSwitchView : EntityListViewType -> msg
    }


update :
    Config msg
    -> LaunchBarMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        NOOP ->
            identity

        OnLBEnter entity ->
            let
                v =
                    case entity of
                        SI_Project project ->
                            project |> getDocId >> Entity.Types.ProjectView

                        SI_Projects ->
                            Entity.Types.ProjectsView

                        SI_Context context ->
                            context |> getDocId >> Entity.Types.ContextView

                        SI_Contexts ->
                            Entity.Types.ContextsView
            in
            returnMsgAsCmd config.onComplete
                >> returnMsgAsCmd (config.onSwitchView v)

        OnLBInputChanged form text ->
            returnWith identity
                (\model ->
                    XMLaunchBar (updateInput config text model form)
                        |> config.setXMode
                        |> returnMsgAsCmd
                )

        Open ->
            config.now
                |> LaunchBar.Models.initialModel
                >> XMLaunchBar
                >> config.setXMode
                >> returnMsgAsCmd

        OnCancel ->
            returnMsgAsCmd config.onComplete


type alias LaunchBarFormF =
    LaunchBarForm -> LaunchBarForm


updateInput : Config msg -> String -> SubModel model -> LaunchBarFormF
updateInput config input subModel form =
    let
        now =
            config.now

        newInput =
            input
                |> (if now - form.updatedAt > 1 * Time.second then
                        Regex.replace (Regex.AtMost 1)
                            (Regex.regex ("^" ++ Regex.escape form.input))
                            (\_ -> "")
                    else
                        identity
                   )

        ( activeContexts, activeProjects ) =
            subModel
                |> apply2
                    ( Model.GroupDocStore.getActiveContexts
                    , Model.GroupDocStore.getActiveProjects
                    )
    in
    { form
        | searchResults = getFuzzyResults input activeContexts activeProjects
        , input = input
        , updatedAt = now
    }


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


getFuzzyResults needle activeContexts activeProjects =
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
