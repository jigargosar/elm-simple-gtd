module ProjectStore exposing (..)

import Dict
import Ext.Random as Random
import Project exposing (EncodedProject, Project, ProjectName)
import ProjectStore.Types exposing (..)
import ProjectStore.Internal as Internal exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Random.Pcg as Random
import Time exposing (Time)


generator =
    Internal.generator


asList =
    Internal.getList


getEncodedProjectNames =
    map (Project.getName >> E.string) >> E.list


getProjectIdToNameDict =
    map (apply2 ( Project.getId, Project.getName )) >> Dict.fromList


findNameById id =
    findById id >> Maybe.map Project.getName


findByName =
    Internal.findByName


addNewProject : ProjectName -> Time -> ProjectStore -> ( Project, ProjectStore )
addNewProject =
    Internal.createAndAdd


insertProjectIfNotExist =
    Internal.addNewIfDoesNotExist
