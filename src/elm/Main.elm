port module Main exposing (..)

import Dom
import EditModel
import Model.EditModel
import Model.RunningTodo
import Project exposing (EncodedProjectList)
import Ext.Random as Random
import Random.Pcg as Random exposing (Seed)
import Ext.Function exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model as Model
import Routes
import Model.Types exposing (..)
import TodoList.Types exposing (..)
import Todo.Types exposing (..)
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
import Todo
import Tuple2
import Function exposing ((>>>))
import Html
import Msg exposing (..)
import RunningTodo
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
    Model.init now encodedTodoList encodedProjectList
        |> Return.singleton
