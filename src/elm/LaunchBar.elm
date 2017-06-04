module LaunchBar exposing (..)

import Context
import Fuzzy
import LaunchBar.Form
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
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
            String.Extra.classify

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


getFuzzyResults needle m =
    let
        contexts =
            Model.getActiveContexts m
                .|> Context

        projects =
            Model.getActiveProjects m
                .|> Project

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
