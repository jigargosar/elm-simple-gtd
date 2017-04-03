module Types exposing (..)

import Ext.Keyboard exposing (KeyboardEvent)
import Model.Types
import RunningTodo exposing (RunningTodo)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Project exposing (Project, ProjectList, ProjectName)
import ProjectList


_ =
    1


type alias DomSelector =
    String
