module ViewModel exposing (..)

import Entity.ViewModel
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Model =
    { contexts : Entity.ViewModel.Model
    , projects : Entity.ViewModel.Model
    }


contextsVM m =
    Entity.ViewModel.contexts m


projectsVM m =
    Entity.ViewModel.projects m


create model =
    Model (contextsVM model) (projectsVM model)
