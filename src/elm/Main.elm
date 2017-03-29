port module Main exposing (..)

import Dom
import EditModeUpdate
import Model.EditMode
import Model.RunningTodo
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model as Model
import Routing
import View exposing (appView)
import Navigation exposing (Location)
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import TodoUpdate exposing (..)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2
import Function exposing ((>>>))
import Html
import Types exposing (..)
import RunningTodoDetails


type alias Flags =
    { now : Time, encodedTodoList : EncodedTodoList }


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routing.delta2hash
        , location2messages = Routing.hash2messages
        , init = init
        , update = update
        , view = appView
        , subscriptions = \m -> Sub.batch [ Time.every Time.second (OnUpdateNow) ]
        }


init : Flags -> Return
init { now, encodedTodoList } =
    Types.Model
        now
        (Todo.decodeTodoList encodedTodoList)
        NotEditing
        defaultViewType
        (Random.seedFromTime now)
        RunningTodoDetails.init
        |> Return.singleton


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            OnEditModeMsg msg ->
                EditModeUpdate.onEditModeMsg msg

            OnTodoMsg msg ->
                TodoUpdate.update msg

            SetMainViewType viewState ->
                Return.map (Model.setMainViewType viewState)

            OnUpdateNow now ->
                onUpdateNow now

            OnMsgList messages ->
                onMsgList messages


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


andThenUpdate =
    update >> Return.andThen


onUpdateNow now =
    Return.map (Model.setNow now)
        >> Return.andThen
            (\m ->
                let
                    shouldBeep =
                        Model.RunningTodo.shouldBeep m
                in
                    if shouldBeep then
                        ( Model.RunningTodo.updateLastBeepedTo now m, startAlarm () )
                    else
                        Return.singleton m
            )


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg
