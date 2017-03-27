port module Main exposing (..)

import Dom
import RandomIdGenerator as Random
import Random.Pcg as Random exposing (Seed)
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Model as Model
import Main.Routing
import Main.View exposing (appView)
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
        { delta2url = Main.Routing.delta2hash
        , location2messages = Main.Routing.hash2messages
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
                onEditModeMsg msg

            OnTodoMsg msg ->
                TodoUpdate.update msg

            SetMainViewType viewState ->
                Return.map (Model.setMainViewType viewState)

            OnUpdateNow now ->
                Return.map (Model.setNow now)

            OnMsgList messages ->
                onMsgList messages


onMsgList : List Msg -> ReturnF
onMsgList =
    flip (List.foldl (update >> Return.andThen))


onEditModeMsg : EditModeMsg -> ReturnF
onEditModeMsg msg =
    case msg of
        AddTodoClicked ->
            activateEditNewTodoMode ""
                >> focusFirstAutoFocusElement

        NewTodoTextChanged text ->
            activateEditNewTodoMode text

        NewTodoBlur ->
            deactivateEditingMode

        NewTodoKeyUp text { key } ->
            case key of
                Enter ->
                    andThenUpdate (Types.saveNewTodo text)
                        >> activateEditNewTodoMode ""

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity

        StartEditingTodo todo ->
            Return.map (Model.activateEditTodoMode todo)
                >> focusFirstAutoFocusElement

        EditTodoTextChanged text ->
            Return.map (Model.updateEditTodoText text)

        EditTodoBlur todo ->
            setTodoTextAndDeactivateEditing todo

        EditTodoKeyUp todo { key, isShiftDown } ->
            case key of
                Enter ->
                    setTodoTextAndDeactivateEditing todo
                        >> whenBool isShiftDown (andThenUpdate (Types.splitNewTodoFrom todo))

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity


andThenUpdate =
    update >> Return.andThen


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)


deactivateEditingModeFor : Todo -> ReturnF
deactivateEditingModeFor =
    Model.deactivateEditingModeFor >> Return.map


activateEditNewTodoMode text =
    Return.map (Model.activateEditNewTodoMode text)


setTodoTextAndDeactivateEditing todo =
    andThenUpdate (Types.setText (Todo.getText todo) (Todo.getId todo))
        >> deactivateEditingModeFor todo


port documentQuerySelectorAndFocus : String -> Cmd msg


focusFirstAutoFocusElement =
    documentQuerySelectorAndFocus ".auto-focus" |> Return.command


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg
