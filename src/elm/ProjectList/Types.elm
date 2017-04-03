module ProjectList.Types exposing (..)

import Project exposing (EncodedProject, Project)
import Random.Pcg exposing (Seed)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)


type ProjectList
    = ProjectList ProjectListModel


type alias ProjectListModel =
    { seed : Seed, list : List Project }


type alias Model =
    ProjectList


type alias ModelF =
    Model -> Model


type alias EncodedProjectList =
    List EncodedProject
