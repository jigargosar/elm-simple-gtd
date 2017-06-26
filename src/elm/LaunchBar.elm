module LaunchBar exposing (..)

import Context
import Fuzzy
import LaunchBar.Form

import Toolkit.Operators exposing (..)




import Project
import String.Extra


type Entity
    = Context Context.Model
    | Project Project.Model
    | Projects
    | Contexts


type Action
    = OnEnter Entity
    | OnInputChanged LaunchBar.Form.Model String
    | Open


getName entity =
    case entity of
        Project project ->
            Project.getName project

        Context context ->
            Context.getName context

        Projects ->
            "Projects"

        Contexts ->
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
            ( '#' :: [], Projects ) ->
                ( entity, match boiledNeedle "#" )

            ( '@' :: [], Contexts ) ->
                ( entity, match boiledNeedle "@" )

            _ ->
                ( entity, match boiledNeedle boiledHay )


getFuzzyResults needle activeContexts activeProjects =
    let
        contexts =
            activeContexts .|> Context

        projects =
            activeProjects .|> Project

        all =
            projects ++ contexts ++ [ Projects, Contexts ]

        entityList =
            case String.toList needle of
                '#' :: xs ->
                    [ Projects ] ++ projects

                '@' :: xs ->
                    [ Contexts ] ++ contexts

                _ ->
                    all
    in
        entityList
            .|> fuzzyMatch needle
            |> List.sortBy (Tuple.second >> (.score))


defaultEntity =
    Context Context.null
