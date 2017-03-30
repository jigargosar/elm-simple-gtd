module Types exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Project exposing (ProjectList, ProjectName)


type MainViewType
    = AllByGroupView
    | GroupView TodoGroup
    | DoneView
    | BinView
    | ProjectsView


defaultViewType =
    AllByGroupView


type alias EditTodoModeModel =
    { todoId : TodoId, todoText : String, projectName : ProjectName }


type EditMode
    = EditNewTodoMode String
    | EditTodoMode EditTodoModeModel
    | NotEditing


createEditTodoMode : Todo -> EditMode
createEditTodoMode =
    apply3 ( Todo.getId, Todo.getText, (\_ -> "Foo") )
        >> uncurry3 EditTodoModeModel
        >> EditTodoMode


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , runningTodoDetails : Maybe RunningTodoDetails
    , projects : ProjectList
    }


type alias ModelF =
    Model -> Model


type TodoFields =
    TodoText String
    | TodoProjectName ProjectName
