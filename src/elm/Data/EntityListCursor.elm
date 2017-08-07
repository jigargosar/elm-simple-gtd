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
import X.List


type alias Model =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    , filter : Filter
    }


initialValue : Model
initialValue =
    create [] Nothing (GroupByFilter ContextGroupDocType)


create : List EntityId -> Maybe EntityId -> Filter -> Model
create entityIdList maybeEntityIdAtCursor filter =
    { entityIdList = entityIdList
    , maybeEntityIdAtCursor = maybeEntityIdAtCursor
    , filter = filter
    }


getMaybeEntityIdAtIndexOrHead : Int -> Model -> Maybe EntityId
getMaybeEntityIdAtIndexOrHead index { entityIdList } =
    X.List.clampAndGetAtIndex index entityIdList
        |> Maybe.orElse (List.head entityIdList)


findEntityIdByOffsetIndex : Int -> Model -> Maybe EntityId
findEntityIdByOffsetIndex offsetIndex model =
    let
        getMaybeIndex : Model -> Maybe Int
        getMaybeIndex model =
            model.maybeEntityIdAtCursor ?+> X.List.firstIndexOfIn model.entityIdList

        index =
            getMaybeIndex model
                ?= 0
                |> add offsetIndex
    in
    getMaybeEntityIdAtIndexOrHead index model
