module ProjectStore.Types exposing (..)

import Project exposing (EncodedProject, Project)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)


type alias ProjectStore =
    { seed : Seed, list : List Project }


type alias Model =
    ProjectStore


type alias ModelF =
    Model -> Model
