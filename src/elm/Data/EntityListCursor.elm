module Data.EntityListCursor exposing (..)

import Data.EntityListFilter exposing (Filter(GroupByFilter))
import Document exposing (DocId)
import Entity exposing (EntityId(TodoEntityId))
import GroupDoc exposing (GroupDocType(ContextGroupDocType))
import List.Extra
import Maybe.Extra
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.List


type alias Model =
    { entityIdList : List EntityId
    , maybeCursorEntityId : Maybe EntityId
    , filter : Filter
    }


initialValue : Model
initialValue =
    create [] Nothing (GroupByFilter ContextGroupDocType)


create : List EntityId -> Maybe EntityId -> Filter -> Model
create entityIdList maybeCursorEntityId filter =
    { entityIdList = entityIdList
    , maybeCursorEntityId = maybeCursorEntityId
    , filter = filter
    }


getMaybeCursorEntityIdIndex : Model -> Maybe Int
getMaybeCursorEntityIdIndex { maybeCursorEntityId, entityIdList } =
    maybeCursorEntityId ?+> X.List.firstIndexOf # entityIdList


findEntityIdByOffsetIndex : Int -> Model -> Maybe EntityId
findEntityIdByOffsetIndex offsetIndex model =
    let
        getMaybeIndex : Model -> Maybe Int
        getMaybeIndex model =
            model.maybeCursorEntityId ?+> X.List.firstIndexOfIn model.entityIdList

        index =
            getMaybeIndex model
                ?= 0
                |> add offsetIndex

        getMaybeEntityIdAtIndexOrHead : Int -> Model -> Maybe EntityId
        getMaybeEntityIdAtIndexOrHead index { entityIdList } =
            X.List.clampAndGetAtIndex index entityIdList
                |> Maybe.Extra.orElse (List.head entityIdList)
    in
    getMaybeEntityIdAtIndexOrHead index model


computeNewEntityIdAtCursor newFilter newEntityIdList cursor =
    let
        maybeCursorEntityId =
            cursor.maybeCursorEntityId

        maybeOldIndex =
            cursor
                |> getMaybeCursorEntityIdIndex

        maybeNewIndex =
            maybeCursorEntityId
                ?+> (X.List.firstIndexOf # newEntityIdList)

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        newMaybeCursorEntityId =
            case ( maybeOldIndex, maybeNewIndex, maybeCursorEntityId ) of
                ( Just oldIndex, Just newIndex, Just (TodoEntityId _) ) ->
                    case compare oldIndex newIndex of
                        LT ->
                            computeMaybeFEI oldIndex

                        GT ->
                            computeMaybeFEI (oldIndex + 1)

                        EQ ->
                            maybeCursorEntityId

                ( Just oldIndex, Nothing, _ ) ->
                    computeMaybeFEI oldIndex

                _ ->
                    maybeCursorEntityId
    in
    (if newFilter == cursor.filter then
        newMaybeCursorEntityId
     else
        cursor.maybeCursorEntityId
    )
        |> Maybe.Extra.orElse (List.head newEntityIdList)
