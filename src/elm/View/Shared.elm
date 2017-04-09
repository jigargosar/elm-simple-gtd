module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import Json.Encode
import Model
import Model.EditMode
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model.Types exposing (EditTodoModel, Model)
import Project exposing (ProjectId, ProjectName)
import Model.Internal as Model
import ProjectStore
import Todo


type alias SharedViewModel =
    { now : Time
    , encodedProjectNames : Json.Encode.Value
    , encodedContextNames : Json.Encode.Value
    , maybeEditTodoModel : Maybe EditTodoModel
    , projectIdToNameDict : Dict ProjectId ProjectName
    , contextByIdDict : Dict Context.Id Context.Model
    , selection : Set Todo.Id
    }


create : Model -> SharedViewModel
create model =
    { now = Model.getNow model
    , encodedProjectNames = Model.getProjectStore model |> ProjectStore.getEncodedProjectNames
    , encodedContextNames = Model.getEncodedContextNames model
    , maybeEditTodoModel = Model.EditMode.getMaybeEditTodoModel model
    , projectIdToNameDict = Model.getProjectStore model |> ProjectStore.getProjectIdToNameDict
    , contextByIdDict = Model.getContextByIdDict model
    , selection = Model.getSelectedTodoIdSet model
    }
