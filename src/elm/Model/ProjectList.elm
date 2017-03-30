module Model.ProjectList exposing (..)

import List.Extra as List
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Project

init = []

getProjectId projectName =
    getProjectById projectName >> Maybe.map Project.getId

getProjectById projectName =
    getProjectList >> List.find (Project.nameEquals projectName)


getProjectList = (.projectList)
