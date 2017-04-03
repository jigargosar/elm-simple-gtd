module Types exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import Model.Types
import RunningTodo exposing (RunningTodo)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Project exposing (Project, ProjectList, ProjectName)


_ =
    1


type alias DomSelector =
    String
