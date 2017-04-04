module ProjectStore
    exposing
        ( generator
        , addNewProject
        , asList
        , getEncodedProjectNames
        , findByName
        , findNameById
        )

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


generator encodedProjectList =
    Random.map
        (\seed ->
            ProjectStoreModel seed (decodeListOfEncodedProjects encodedProjectList) |> ProjectStore
        )
        Random.independentSeed


asList =
    Internal.getList


getEncodedProjectNames =
    map (Project.getName >> E.string) >> E.list


findNameById id =
    findById id >> Maybe.map Project.getName


findByName projectName =
    findBy (Project.nameEquals projectName)


addNewProject : ProjectName -> Time -> ProjectStore -> ( Project, ProjectStore )
addNewProject projectName now =
    generate (Project.generator projectName now)
        >> addFromTuple
