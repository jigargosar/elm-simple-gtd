module Types exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import Model.Types
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Project exposing (Project, ProjectList, ProjectName)


type TodoField
    = TodoText String
    | TodoProject Project
