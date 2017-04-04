module ProjectStore exposing (..)

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
    Random.map (\seed -> ProjectStoreModel seed (decodeListOfEncodedProjects encodedProjectList) |> ProjectStore) Random.independentSeed


decodeListOfEncodedProjects : List EncodedProject -> List Project
decodeListOfEncodedProjects =
    List.map (D.decodeValue Project.decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok project ->
                        Just project

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding Project"
                        in
                            Nothing
            )


getList =
    Internal.getList


getEncodedProjectNames =
    getList >> List.map (Project.getName >> E.string) >> E.list


findIdByName =
    findByName >>> Maybe.map Project.getId


findByName projectName =
    getList >> List.find (Project.nameEquals projectName)


findProjectById id =
    getList >> List.find (Project.getId >> equals id)


addNewProject : ProjectName -> Time -> ProjectStore -> ( Project, ProjectStore )
addNewProject projectName now =
    generate (Project.generator projectName now)
        >> addProjectFromTuple


addProjectFromTuple : ( Project, ProjectStore ) -> ( Project, ProjectStore )
addProjectFromTuple =
    apply2 ( Tuple.first, uncurry addProject )


addProject project =
    updateList (getList >> (::) project)


findProjectNameById id =
    findProjectById id >> Maybe.map Project.getName
