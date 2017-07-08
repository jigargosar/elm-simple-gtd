module LaunchBar exposing (..)

import Context
import Fuzzy
import LaunchBar.Form
import LaunchBar.Types exposing (LaunchBarForm)
import Toolkit.Operators exposing (..)
import Project
import String.Extra


type LBEntity
    = LBContext Context.Model
    | LBProject Project.Model
    | LBProjects
    | LBContexts


type Msg
    = OnLBEnter LBEntity
    | OnLBInputChanged LaunchBarForm String
    | OnLBOpen


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
