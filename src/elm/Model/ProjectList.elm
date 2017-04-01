module Model.ProjectList exposing (..)

import Json.Encode
import List.Extra as List
import Model
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Project exposing (Project, ProjectId, ProjectList, ProjectName)
import Model.Types exposing (..)


getEncodedProjectNames =
    getProjectList >> List.map (Project.getName >> Json.Encode.string) >> Json.Encode.list


getProjectIdByName projectName =
    getProjectByName projectName >> Maybe.map Project.getId


getProjectByName projectName =
    getProjectList >> List.find (Project.nameEquals projectName)


getProjectByMaybeId : Maybe ProjectId -> Model -> Maybe Project
getProjectByMaybeId maybeProjectId model =
    maybeProjectId ?+> getProjectById # model


getProjectById id =
    getProjectList >> List.find (Project.getId >> equals id)


addNewProject : ProjectName -> Model -> ( Project, Model )
addNewProject projectName model =
    model
        |> Model.generate (Project.projectGenerator projectName (Model.getNow model))
        >> addProjectFromTuple


addProjectFromTuple : ( Project, Model ) -> ( Project, Model )
addProjectFromTuple =
    apply2 ( Tuple.first, uncurry addProject )


addProject project =
    updateProjectList (getProjectList >> (::) project)


getProjectList : Model -> ProjectList
getProjectList =
    (.projectList)


setProjectList : ProjectList -> ModelF
setProjectList projectList model =
    { model | projectList = projectList }


updateProjectList : (Model -> ProjectList) -> ModelF
updateProjectList updater model =
    setProjectList (updater model) model
