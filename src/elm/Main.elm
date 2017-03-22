port module Main exposing (..)

import Dom
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


type alias ReturnTA =
    Return Msg Model


type alias ReturnMapper =
    ReturnTA -> ReturnTA


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
        , subscriptions = subscriptions
        }


subscriptions m =
    Sub.batch
        []


init : Flags -> ReturnTA
init { now, encodedTodoList } =
    Model.init now encodedTodoList |> Return.singleton


update : Msg -> Model -> ReturnTA
update msg =
    Return.singleton
        >> case msg of
            NoOp ->
                identity

            LocationChanged loc ->
                identity

            OnAddTodoClicked focusInputId ->
                Return.map (Model.activateEditNewTodoMode "")
                    >> domFocus focusInputId OnDomResult

            OnNewTodoTextChanged text ->
                Return.map (Model.activateEditNewTodoMode text)

            OnNewTodoBlur ->
                deactivateEditingMode

            OnNewTodoKeyUp text key ->
                case key of
                    Enter ->
                        addNewTodoAndContinueAdding text

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            OnEditTodoClicked focusInputId todo ->
                Return.map (Model.activateEditTodoMode todo)
                    >> domFocus focusInputId OnDomResult

            OnDomResult result ->
                let
                    _ =
                        result |> Result.mapError (Debug.log "Error: Dom")
                in
                    identity

            OnEditTodoTextChanged text ->
                Return.map (Model.updateEditTodoText text)

            OnEditTodoBlur todo ->
                setTodoTextAndDeactivateEditing todo

            OnEditTodoKeyUp todo key ->
                case key of
                    Enter ->
                        setTodoTextAndDeactivateEditing todo

                    Escape ->
                        deactivateEditingMode

                    _ ->
                        identity

            OnShowTodoList ->
                Return.map (Model.showTodoList)

            ProcessInbox ->
                Return.map (Model.startProcessingInbox)

            OnSetTodoGroupClicked todoGroup todo ->
                onTodoListMsg (TodoList.setGroup todoGroup (Todo.getId todo))

            OnDeleteTodoClicked todoId ->
                onTodoListMsg (TodoList.delete todoId)

            OnTodoDoneClicked todoId ->
                onTodoListMsg (TodoList.toggleDone todoId)

            OnTodoListMsg msg ->
                Return.andThen (TodoList.update msg >> Return.mapCmd OnTodoListMsg)



--            _ ->
--                let
--                    _ =
--                        Debug.log "WARN: msg ignored" (msg)
--                in
--                    identity


onTodoListMsg =
    OnTodoListMsg >> update >> Return.andThen


domFocusCmd id msg =
    Task.attempt msg (Dom.focus id)


domFocus =
    domFocusCmd >>> Return.command


addNewTodoAndContinueAdding text =
    onTodoListMsg (TodoList.addNewTodo text)
        >> activateEditNewTodoMode


activateEditNewTodoMode =
    Return.map (Model.activateEditNewTodoMode "")


setTodoTextAndDeactivateEditing todo =
    onTodoListMsg (TodoList.setText (Todo.getText todo) (Todo.getId todo))
        >> deactivateEditingMode


deactivateEditingMode =
    Return.map (Model.deactivateEditingMode)
