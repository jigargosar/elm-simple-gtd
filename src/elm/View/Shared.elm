module View.Shared exposing (..)

import Context
import Dict exposing (Dict)
import EditMode exposing (EditTodoModel)
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
import Model.Types exposing (Model)
import Project
import Model.Internal as Model
import Project
import Todo


type alias SharedViewModel =
    { now : Time
    , encodedProjectNames : Json.Encode.Value
    , encodedContextNames : Json.Encode.Value
    , maybeEditTodoModel : Maybe EditTodoModel
    , projectIdToNameDict : Dict Project.Id Project.Name
    , contextByIdDict : Dict Context.Id Context.Model
    , selection : Set Todo.Id
    }


create : Model -> SharedViewModel
create model =
    { now = Model.getNow model
    , encodedProjectNames = Model.getProjectStore model |> Project.getEncodedProjectNames
    , encodedContextNames = Model.getEncodedContextNames model
    , maybeEditTodoModel = Model.EditMode.getMaybeEditTodoModel model
    , projectIdToNameDict = Model.getProjectStore model |> Project.getProjectIdToNameDict
    , contextByIdDict = Model.getContextByIdDict model
    , selection = Model.getSelectedTodoIdSet model
    }
