module LaunchBar exposing (..)

import Context
import Fuzzy
import Model
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project


type SearchEntity
    = Context Context.Model
    | Project Project.Model


getName entity =
    case entity of
        Project project ->
            Project.getName project

        Context context ->
            Context.getName context


getFuzzyResults needle entityList =
    entityList
        .|> getName
        >> String.toLower
        >> Fuzzy.match [] [ " " ] (String.toLower needle)
        |> List.zip entityList
        |> List.sortBy (Tuple.second >> (.score))


toViewType entity =
    case entity of
        Project project ->
            Model.projectView project

        Context context ->
            Model.contextView context
