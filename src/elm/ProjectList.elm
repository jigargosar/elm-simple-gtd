module ProjectList exposing (..)

import Project exposing (Project, ProjectName)
import ProjectList.Types exposing (..)
import ProjectList.Internal as Internal exposing (..)
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
    Random.map (\seed -> ProjectListModel seed (decodeList encodedProjectList) |> ProjectList) Random.independentSeed


decodeList : EncodedProjectList -> List Project
decodeList =
    List.map (D.decodeValue Project.decoder)
        >> List.filterMap
            (\result ->
                case result of
                    Ok todo ->
                        Just todo

                    Err x ->
                        let
                            _ =
                                Debug.log "Error while decoding todo"
                        in
                            Nothing
            )


getList =
    Internal.getList


getEncodedProjectNames =
    getList >> List.map (Project.getName >> E.string) >> E.list


getProjectIdByName =
    findProjectByName >>> Maybe.map Project.getId


findProjectByName projectName =
    getList >> List.find (Project.nameEquals projectName)


findProjectById id =
    getList >> List.find (Project.getId >> equals id)


addNewProject : ProjectName -> Time -> ProjectList -> ( Project, ProjectList )
addNewProject projectName now =
    generate (Project.projectGenerator projectName now)
        >> addProjectFromTuple


generate : Random.Generator a -> ProjectList -> ( a, ProjectList )
generate generator m =
    Random.step generator (getSeed m)
        |> Tuple.mapSecond (setSeed # m)


addProjectFromTuple : ( Project, ProjectList ) -> ( Project, ProjectList )
addProjectFromTuple =
    apply2 ( Tuple.first, uncurry addProject )


addProject project =
    updateList (getList >> (::) project)
