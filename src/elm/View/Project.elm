module View.Project exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types exposing (Entity(ProjectEntity), EntityAction(Delete), MainViewType(ProjectView))
import Msg exposing (Msg)
import PouchDB
import Project
import String.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Todo
import View.Entity


vmList : Model.Types.Model -> List View.Entity.ViewModel
vmList model =
    let
        todoByGroupIdDict =
            Model.getActiveTodoListGroupedByProjectId model
    in
        Model.getActiveProjects model
            |> (::) Project.null
            .|> View.Entity.createVM todoByGroupIdDict
                    { createEntity = ProjectEntity
                    , getId = Project.getId
                    , isNull = Project.isNull
                    , getName = Project.getName
                    , getViewType = ProjectView
                    }
