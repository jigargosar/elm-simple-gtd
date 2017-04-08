port module Main exposing (..)

import Context
import Dom
import Ext.Keyboard as Keyboard
import Model.EditMode
import Model.RunningTodo
import Project exposing (EncodedProject)
import Ext.Random as Random
import Random.Pcg as Random exposing (Seed)
import Ext.Function exposing (..)
import Json.Encode as E
import Model as Model
import Routes
import Model.Types exposing (..)
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
    , encodedTodoList : List EncodedTodo
    , encodedProjectList : List EncodedProject
    , encodedContextList : List Context.Encoded
    }


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = Update.update
        , view = appView
        , subscriptions = subscriptions
        }


init : Flags -> Return
init { now, encodedTodoList, encodedProjectList, encodedContextList } =
    Model.init now encodedTodoList encodedProjectList encodedContextList
        |> Return.singleton


subscriptions m =
    Sub.batch
        [ Time.every Time.second (OnNowChanged)
        , Keyboard.subscription OnKeyboardMsg
        , Keyboard.keyUps OnKeyUp
        ]
