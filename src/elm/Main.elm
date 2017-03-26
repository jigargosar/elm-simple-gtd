port module Main exposing (..)

import Dom
import DomTypes exposing (DomId)
import DomUpdate
import FunctionExtra exposing (..)
import Json.Encode as E
import Keyboard.Extra exposing (Key(Enter, Escape))
import Main.Model as Model exposing (Model)
import Main.Msg as Msg exposing (..)
import Main.Routing
import Main.View exposing (appView)
import Navigation exposing (Location)
import Return exposing (Return)
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import PouchDB
import TodoList
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Maybe.Extra as Maybe
import Todo as Todo exposing (EncodedTodoList, Todo, TodoId)
import Tuple2
import Function exposing ((>>>))
import Html


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
        , subscriptions = \m -> Sub.batch [ Time.every Time.second (UpdateNow) ]
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
                onTodoListMsg (TodoList.setGroup todoGroup todoId)

            OnDeleteTodoClicked todoId ->
                onTodoListMsg (TodoList.toggleDelete todoId)

            OnTodoDoneClicked todoId ->
                onTodoListMsg (TodoList.toggleDone todoId)

            OnTodoMsg msg ->
                Return.andThen
                    (TodoList.update
                        update
                        msg
                    )

            OnDomMsg msg ->
                Return.andThen (DomUpdate.update msg >> Return.mapCmd OnDomMsg)

            SetMainViewType viewState ->
                Return.map (Model.setMainViewType viewState)

            UpdateNow now ->
                Return.map (Model.setNow now)


onNewTodoMsg msg =
    let
        activateEditNewTodoMode text =
            Return.map (Model.activateEditNewTodoMode text)
    in
        case msg of
            AddTodoClicked focusInputId ->
                activateEditNewTodoMode ""
                    >> domFocus focusInputId

            NewTodoTextChanged text ->
                activateEditNewTodoMode text

            NewTodoBlur ->
                deactivateEditingMode

            NewTodoKeyUp text { key } ->
                case key of
                    Enter ->
                        onTodoListMsg (TodoList.addNewTodo text)
                            >> activateEditNewTodoMode ""

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity


onEditTodoMsg msg =
    let
        setTodoTextAndDeactivateEditing todo =
            onTodoListMsg (TodoList.setText (Todo.getText todo) (Todo.getId todo))
                >> deactivateEditingMode
    in
        case msg of
            EditTodoClicked focusInputId todo ->
                Return.map (Model.activateEditTodoMode todo)
                    >> domFocus focusInputId

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
                                >> whenBool isShiftDown (onTodoListMsg (TodoList.splitNewTodoFrom todo))

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity


onTodoListMsg =
    OnTodoMsg >> update >> Return.andThen


onDomMsg =
    OnDomMsg >> update >> Return.andThen


domFocus : DomId -> ReturnF
domFocus =
    DomTypes.focus >> onDomMsg


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)
