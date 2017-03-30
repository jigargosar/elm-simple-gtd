module Model.ProjectList exposing (..)

import List.Extra as List
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Project exposing (ProjectList, ProjectName)
import Types exposing (Model, ModelF)


init =
    []


getProjectIdByName projectName =
    getProjectByName projectName >> Maybe.map Project.getId


getProjectByName projectName =
    getProjectList >> List.find (Project.nameEquals projectName)


createProject : ProjectName -> ModelF
createProject projectName =
    updateProjectList (getProjectList >> (::) (Project.create projectName))


getProjectList : Model -> ProjectList
getProjectList =
    (.projectList)


setProjectList : ProjectList -> ModelF
setProjectList projectList model =
    { model | projectList = projectList }


updateProjectList : (Model -> ProjectList) -> ModelF
updateProjectList updater model =
    setProjectList (updater model) model
