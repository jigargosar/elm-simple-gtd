module ProjectList exposing (..)

import Project exposing (Project, ProjectName)
import ProjectList.Types exposing (..)
import ProjectList.Internal exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Random.Pcg as Random


decodeProjectList : EncodedProjectList -> ProjectList
decodeProjectList =
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


getEncodedProjectNames =
    List.map (Project.getName >> Json.Encode.string) >> Json.Encode.list


getProjectIdByName =
    findProjectByName >>> Maybe.map Project.getId


findProjectByName projectName =
    List.find (Project.nameEquals projectName)


findProjectById id =
    List.find (Project.getId >> equals id)


addNewProject : ProjectName -> Model -> ( Project, Model )
addNewProject projectName now =
    generate (Project.projectGenerator projectName now)
        >> addProjectFromTuple


generate : Random.Generator a -> Model -> ( a, Model )
generate generatorFn m =
    Random.step (generatorFn m) (getSeed m)
        |> Tuple.mapSecond (setSeed # m)


addProjectFromTuple : ( Project, Model ) -> ( Project, Model )
addProjectFromTuple =
    apply2 ( Tuple.first, uncurry addProject )


addProject project =
    updateList (getList >> (::) project)
