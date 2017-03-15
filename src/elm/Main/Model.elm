module Main.Model exposing (..)

import Main.Msg exposing (Msg)
import Return exposing (Return)
import Todos exposing (EditMode(..), TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todos.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2


type alias Model =
    { todosModel : TodosModel
    , editMode : EditMode
    }


type alias ReturnMapper =
    Return Msg Model -> Return Msg Model


initWithTime : Time -> Model
initWithTime =
    round >> Random.initialSeed >> initWithSeed


initWithSeed : Seed -> Model
initWithSeed seed =
    { todosModel = Random.step Todos.todoModelGenerator seed |> Tuple.first
    , editMode = NotEditing
    }


getTodosModel : Model -> TodosModel
getTodosModel =
    (.todosModel)


setEditModeTo : EditMode -> ReturnMapper
setEditModeTo editMode =
    Return.map (\m -> { m | editMode = editMode })


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateAddNewTodoMode : String -> ReturnMapper
activateAddNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


activateEditTodoMode : Todo -> ReturnMapper
activateEditTodoMode todo =
    setEditModeTo (EditTodoMode todo)


updateEditTodoText : String -> ReturnMapper
updateEditTodoText text =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry (updateEditTodoTextHelp text))


updateEditTodoTextHelp : String -> EditMode -> ReturnMapper
updateEditTodoTextHelp text editMode =
    case editMode of
        EditTodoMode todo ->
            setEditModeTo (EditTodoMode (Todo.setText text todo))

        _ ->
            identity


setTodosModel : TodosModel -> ReturnMapper
setTodosModel todosModel =
    Return.map (\m -> { m | todosModel = todosModel })


addNewTodoAndDeactivateAddNewTodoMode : ReturnMapper
addNewTodoAndDeactivateAddNewTodoMode =
    addNewTodo
        >> setEditModeTo NotEditing


saveEditingTodoAndDeactivateEditTodoMode : ReturnMapper
saveEditingTodoAndDeactivateEditTodoMode =
    saveEditingTodo
        >> setEditModeTo NotEditing


saveEditingTodo : ReturnMapper
saveEditingTodo =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry saveEditingTodoHelp)


saveEditingTodoHelp : EditMode -> ReturnMapper
saveEditingTodoHelp editMode =
    case editMode of
        EditTodoMode todo ->
            if Todo.isTextEmpty todo then
                identity
            else
                Return.map (\m -> ( Todos.replaceTodoIfIdMatches todo m.todosModel, Return.singleton m ))
                    >> Return.andThen (uncurry setTodosModel)

        _ ->
            identity


addNewTodoAndContinueAdding : ReturnMapper
addNewTodoAndContinueAdding =
    addNewTodo
        >> activateAddNewTodoMode ""


addNewTodo : ReturnMapper
addNewTodo =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry createAndAddNewTodo)


createAndAddNewTodo : EditMode -> ReturnMapper
createAndAddNewTodo editMode =
    case editMode of
        EditNewTodoMode text ->
            if String.trim text |> String.isEmpty then
                identity
            else
                Return.andThen
                    (\m ->
                        Todos.addNewTodo text m.todosModel
                            |> Tuple2.mapEach ((,) # m) (\addedTodo -> Cmd.none)
                    )
                    >> setTodosModelFromTuple

        _ ->
            identity


setTodosModelFromTuple =
    Return.map (\( todosModel, m ) -> { m | todosModel = todosModel })


deleteTodo todoId =
    Return.map (\m -> ( Todos.deleteTodo todoId m.todosModel, Return.singleton m ))
        >> Return.andThen (uncurry setTodosModel)
