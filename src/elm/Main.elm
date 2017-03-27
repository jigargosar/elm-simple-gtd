port module Main exposing (..)

import Dom
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Model as Model exposing (Model)
import Msg as Msg exposing (..)
import Main.Routing
import Main.View exposing (appView)
import Navigation exposing (Location)
import Return exposing (Return)
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import TodoListUpdate exposing (..)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2
import Function exposing ((>>>))
import Html
import TodoListMsg


type alias Return =
    Return.Return Msg Model


type alias ReturnF =
    Return -> Return


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
    Model.init now encodedTodoList |> Return.singleton


update : Msg -> Model -> Return
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            OnNewTodoMsg msg ->
                onNewTodoMsg msg

            OnEditTodoMsg msg ->
                onEditTodoMsg msg

            OnSetTodoGroupClicked todoGroup todoId ->
                onTodoListMsg (TodoListMsg.setGroup todoGroup todoId)

            OnDeleteTodoClicked todoId ->
                onTodoListMsg (TodoListMsg.toggleDelete todoId)

            OnTodoDoneClicked todoId ->
                onTodoListMsg (TodoListMsg.toggleDone todoId)

            OnTodoMsg msg ->
                Return.andThen
                    (TodoListUpdate.update
                        update
                        msg
                    )

            SetMainViewType viewState ->
                Return.map (Model.setMainViewType viewState)

            OnUpdateNow now ->
                Return.map (Model.setNow now)


onNewTodoMsg msg =
    let
        activateEditNewTodoMode text =
            Return.map (Model.activateEditNewTodoMode text)
    in
        case msg of
            AddTodoClicked focusInputId ->
                activateEditNewTodoMode ""
                    >> focusFirstAutoFocusElement

            NewTodoTextChanged text ->
                activateEditNewTodoMode text

            NewTodoBlur ->
                deactivateEditingMode

            NewTodoKeyUp text { key } ->
                case key of
                    Enter ->
                        onTodoListMsg (TodoListMsg.addNewTodo text)
                            >> activateEditNewTodoMode ""

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity


onEditTodoMsg msg =
    let
        setTodoTextAndDeactivateEditing todo =
            onTodoListMsg (TodoListMsg.setText (Todo.getText todo) (Todo.getId todo))
                >> deactivateEditingModeFor todo
    in
        case msg of
            EditTodoClicked todo ->
                Return.map (Model.activateEditTodoMode todo)
                    >> focusFirstAutoFocusElement

            EditTodoTextChanged text ->
                Return.map (Model.updateEditTodoText text)

            EditTodoBlur todo ->
                setTodoTextAndDeactivateEditing todo

            EditTodoKeyUp todo { key, isShiftDown } ->
                case key of
                    Enter ->
                        let
                            _ =
                                Debug.log "EditTodoKeyUp" ("enter presseed")
                        in
                            setTodoTextAndDeactivateEditing todo
                                >> whenBool isShiftDown (onTodoListMsg (TodoListMsg.splitNewTodoFrom todo))

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity


onTodoListMsg =
    OnTodoMsg >> update >> Return.andThen


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)


deactivateEditingModeFor : Todo -> ReturnF
deactivateEditingModeFor =
    Model.deactivateEditingModeFor >> Return.map


port documentQuerySelectorAndFocus : String -> Cmd msg


focusFirstAutoFocusElement =
    documentQuerySelectorAndFocus ".auto-focus" |> Return.command


port startAlarm : () -> Cmd msg


port stopAlarm : () -> Cmd msg
