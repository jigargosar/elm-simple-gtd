module LaunchBar.Update exposing (..)

import Context
import DomPorts exposing (autoFocusInputCmd)
import Entity.Types
import Fuzzy
import GroupDoc.Types exposing (ContextDoc, GroupDoc, ProjectDoc)
import LaunchBar.Messages exposing (LBMsg(..))
import LaunchBar.Models exposing (..)
import Model.ExMode
import Model.ViewType
import Msg
import Project
import Regex
import Return
import String.Extra
import Time exposing (Time)
import Types exposing (ReturnF)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type alias Config =
    { now : Time
    , activeProjects : List ContextDoc
    , activeContexts : List ProjectDoc
    }


map =
    Return.map


update :
    Config
    -> LBMsg
    -> LaunchBar
    -> ( LaunchBar, Cmd LBMsg )
update config msg =
    Return.singleton
        >> case msg of
            NOOP ->
                identity

            OnLBEnter entity ->
                map (\model -> { model | maybeResult = Selected entity |> Just })

            OnLBInputChanged form text ->
                map (updateInput config text)

            OnLBOpen ->
                map (\m -> { m | maybeResult = Nothing })
                    >> DomPorts.autoFocusInputCmd

            OnCancel ->
                map (\m -> { m | maybeResult = Just Canceled })


type alias LaunchBarF =
    LaunchBar -> LaunchBar


updateInput : Config -> String -> LaunchBarF
updateInput config input model =
    let
        now =
            config.now

        newInput =
            input
                |> if now - model.updatedAt > 1 * Time.second then
                    Regex.replace (Regex.AtMost 1)
                        (Regex.regex ("^" ++ Regex.escape model.input))
                        (\_ -> "")
                   else
                    identity
    in
        updateInputHelp newInput model now
            |> (\model ->
                    { model | searchResults = getFuzzyResults input config }
               )


updateInputHelp input model now =
    { model | input = input }
        |> (\model -> { model | updatedAt = now })


fuzzyMatch needle entity =
    let
        --        boil = String.toLower
        boil =
            String.Extra.underscored

        boiledHay =
            entity |> getSearchItemName >> boil

        boiledNeedle =
            boil needle

        match n =
            Fuzzy.match [] [] n
    in
        ( entity, match boiledNeedle boiledHay )


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
