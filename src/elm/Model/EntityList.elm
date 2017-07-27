module Model.EntityList exposing (..)

import Entity
import Entity.Tree
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Model.EntityTree
import Model.HasFocusInEntity exposing (HasFocusInEntity)
import Model.HasStores exposing (..)
import Model.ViewType
import Toolkit.Operators exposing (..)
import Tuple2
import X.List


-- todo move to Update.Entity


createEntityListForCurrentView model =
    Model.ViewType.maybeGetEntityListViewType model
        ?|> (Model.EntityTree.createEntityTreeForViewType # model >> Entity.Tree.flatten)
        ?= []
