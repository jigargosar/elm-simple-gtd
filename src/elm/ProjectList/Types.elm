module ProjectList.Types exposing (..)

import Project exposing (Project)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)


type ProjectList
    = ProjectList Model


type alias Model =
    { seed : Seed, list : List Project }
