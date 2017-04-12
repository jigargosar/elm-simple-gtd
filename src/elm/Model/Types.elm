module Model.Types exposing (..)

import Context
import EditMode exposing (EditMode)
import Ext.Keyboard as Keyboard
import PouchDB
import Project
import Project
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo


type alias Selection =
    Set Todo.Id


type MainViewType
    = GroupByContextView
    | ProjectView Project.Id
    | DoneView
    | BinView
    | GroupByProjectView
    | ContextView Context.Id


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editMode : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , maybeRunningTodo : Maybe RunningTodo
    , keyboardState : Keyboard.State
    , selection : Selection
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model


type EntityAction
    = StartEditing
    | Delete


type Entity
    = ProjectEntity Project.Model
    | ContextEntity Context.Model


type EntityType
    = ProjectEntityType
    | ContextEntityType


type EntityStoreType
    = ProjectEntityStoreType
    | ContextEntityStoreType


type alias EntityId =
    PouchDB.Id
