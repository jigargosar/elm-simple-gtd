module LaunchBar.Models exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
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


type alias LaunchBar =
    { input : String
    , updatedAt : Time
    }


type alias ModelF =
    LaunchBar -> LaunchBar


create now =
    { input = ""
    , updatedAt = now
    }


updateInput : Time -> String -> ModelF
updateInput now input model =
    let
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
        case ( String.toList needle, entity ) of
            ( '#' :: [], LBProjects ) ->
                ( entity, match boiledNeedle "#" )

            ( '@' :: [], LBContexts ) ->
                ( entity, match boiledNeedle "@" )

            _ ->
                ( entity, match boiledNeedle boiledHay )


getFuzzyResults needle activeContexts activeProjects =
    let
        contexts =
            activeContexts .|> LBContext

        projects =
            activeProjects .|> LBProject

        all =
            projects ++ contexts ++ [ LBProjects, LBContexts ]

        entityList =
            case String.toList needle of
                '#' :: xs ->
                    [ LBProjects ] ++ projects

                '@' :: xs ->
                    [ LBContexts ] ++ contexts

                _ ->
                    all
    in
        entityList
            .|> fuzzyMatch needle
            |> List.sortBy (Tuple.second >> (.score))


defaultEntity =
    LBContext Context.null
