module LaunchBar.Models exposing (..)

import GroupDoc.Types exposing (ContextDoc, GroupDoc, ProjectDoc)
import Regex
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import Context
import Fuzzy
import Toolkit.Operators exposing (..)
import Project
import String.Extra


type LBEntity
    = LBContext ContextDoc
    | LBProject ProjectDoc
    | LBProjects
    | LBContexts


type alias SearchItem a =
    { getSearchText : a -> String
    , item : a
    }


type Result
    = Canceled
    | Selected LBEntity


type alias LaunchBar =
    { input : String
    , updatedAt : Time
    , searchResults : List ( LBEntity, Fuzzy.Result )
    , maybeResult : Maybe Result
    }


type alias LaunchBarF =
    LaunchBar -> LaunchBar


initialModel : Time -> LaunchBar
initialModel now =
    { input = ""
    , updatedAt = now
    , searchResults = []
    , maybeResult = Nothing
    }


type alias Config =
    { now : Time
    , activeProjects : List GroupDoc
    , activeContexts : List GroupDoc
    }


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


getName entity =
    case entity of
        LBProject project ->
            Project.getName project

        LBContext context ->
            Context.getName context

        LBProjects ->
            "Projects"

        LBContexts ->
            "Contexts"


fuzzyMatch needle entity =
    let
        --        boil = String.toLower
        boil =
            String.Extra.underscored

        boiledHay =
            entity |> getName >> boil

        boiledNeedle =
            boil needle

        match n =
            Fuzzy.match [] [] n
    in
        ( entity, match boiledNeedle boiledHay )


fuzzyMatch2 needle hay =
    let
        boil =
            String.Extra.underscored

        boiledHay =
            hay.getSearchText hay.item |> boil

        boiledNeedle =
            boil needle

        match n =
            Fuzzy.match [] [] n
    in
        ( hay, match boiledNeedle boiledHay )


getFuzzyResults needle { activeContexts, activeProjects } =
    let
        contexts =
            activeContexts .|> LBContext

        projects =
            activeProjects .|> LBProject

        all =
            projects ++ contexts ++ [ LBProjects, LBContexts ]

        {- entityList =
           case String.toList needle of
               '#' :: xs ->
                   [ LBProjects ] ++ projects

               '@' :: xs ->
                   [ LBContexts ] ++ contexts

               _ ->
                   all
        -}
    in
        all
            .|> fuzzyMatch needle
            |> List.sortBy (Tuple.second >> (.score))


getFuzzyResults2 needle activeContexts activeProjects =
    let
        contexts =
            activeContexts .|> LBContext

        projects =
            activeProjects .|> LBProject

        all =
            projects ++ contexts ++ [ LBProjects, LBContexts ]
    in
        all
            .|> (toSI >> fuzzyMatch2 needle)
            |> List.sortBy (Tuple.second >> (.score))


toSI =
    (\e -> SearchItem getName e)


defaultEntity =
    LBContext Context.null


defaultEntity2 =
    LBContext Context.null |> toSI
