module EntityList exposing (..)

import EntityList.GroupViewModel
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


createContextGroupViewModel =
    EntityList.GroupViewModel.forContext


createProjectGroupViewModel =
    EntityList.GroupViewModel.forProject
