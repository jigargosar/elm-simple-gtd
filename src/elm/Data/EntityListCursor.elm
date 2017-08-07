module Data.EntityListCursor exposing (..)

import Data.EntityListFilter exposing (Filter(GroupByFilter))
import Document exposing (DocId)
import Entity exposing (EntityId)
import GroupDoc exposing (GroupDocType(ContextGroupDocType))
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    , filter : Filter
    }


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    , filter = GroupByFilter ContextGroupDocType
    }
