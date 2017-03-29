module Update.EditModeUpdate exposing (..)

import DomPorts exposing (focusFirstAutoFocusElement)
import Keyboard.Extra exposing (Key(Enter, Escape))
import Model.EditMode
import Return
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Types exposing (EditModeMsg(..), ReturnF)


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
                    Return.command (Types.saveNewTodo text |> Types.toCmd)
                        >> activateEditNewTodoMode ""

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity

        StartEditingTodo todo ->
            Return.map (Model.EditMode.activateEditTodoMode todo)
                >> focusFirstAutoFocusElement

        EditTodoTextChanged text ->
            Return.map (Model.EditMode.updateEditTodoText text)

        EditTodoBlur todo ->
            setTodoTextAndDeactivateEditing todo

        EditTodoKeyUp todo { key, isShiftDown } ->
            case key of
                Enter ->
                    setTodoTextAndDeactivateEditing todo
                        >> whenBool isShiftDown
                            (Return.command (Types.splitNewTodoFrom todo |> Types.toCmd))

                Escape ->
                    deactivateEditingMode

                _ ->
                    identity


deactivateEditingMode =
    Return.map (Model.EditMode.deactivateEditingMode)


deactivateEditingModeFor : Todo -> ReturnF
deactivateEditingModeFor =
    Model.EditMode.deactivateEditingModeFor >> Return.map


activateEditNewTodoMode text =
    Return.map (Model.EditMode.activateEditNewTodoMode text)


setTodoTextAndDeactivateEditing todo =
    Return.command (Types.setText (Todo.getText todo) (Todo.getId todo) |> Types.toCmd)
        >> deactivateEditingModeFor todo
