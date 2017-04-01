port module Main exposing (..)

import Dom
import Model.EditMode
import Model.ProjectList
import Model.RunningTodo
import Project exposing (EncodedProjectList)
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model as Model
import Routes
import Model.Types exposing (..)
import View exposing (appView)
import Navigation exposing (Location)
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2
import Function exposing ((>>>))
import Html
import Msg exposing (..)
import RunningTodoDetails
import Update


type alias Flags =
    { now : Time
    , encodedTodoList : EncodedTodoList
    , encodedProjectList : EncodedProjectList
    }


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = Update.update
        , view = appView
        , subscriptions = \m -> Sub.batch [ Time.every Time.second (OnNowChanged) ]
        }


init : Flags -> Return
init { now, encodedTodoList, encodedProjectList } =
    { now = now
    , todoList = Todo.decodeTodoList encodedTodoList
    , editMode = None
    , mainViewType = defaultViewType
    , seed = Random.seedFromTime now
    , runningTodoDetails = RunningTodoDetails.init
    , projectList = Project.decodeProjectList encodedProjectList
    }
        |> Return.singleton
