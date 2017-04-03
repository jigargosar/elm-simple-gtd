module Model.ProjectList exposing (..)

import Json.Encode
import List.Extra as List
import Model
import Model.Internal exposing (..)
import ProjectList
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Project exposing (Project, ProjectId, ProjectName)
import Model.Types exposing (..)
import ProjectList.Types exposing (ProjectList)


addNewProject : ProjectName -> Model -> ( Project, Model )
addNewProject projectName =
    Model.generate (Model.getNow >> Project.projectGenerator projectName)
        >> addProjectFromTuple


addProjectFromTuple : ( Project, Model ) -> ( Project, Model )
addProjectFromTuple =
    apply2 ( Tuple.first, uncurry addProject )


addProject project =
    updateProjectList (getProjectList >> ProjectList.addProject project)
