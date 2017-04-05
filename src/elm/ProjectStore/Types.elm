module ProjectStore.Types exposing (..)

import PouchDB
import Project exposing (EncodedProject, Project, ProjectName)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)


type alias ProjectStore =
    PouchDB.Store Project.OtherFields


type alias Model =
    ProjectStore


type alias ModelF =
    Model -> Model
