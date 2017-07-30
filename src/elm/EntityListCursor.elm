module EntityListCursor exposing (..)

import Entity
import Entity.Tree
import Entity.Types exposing (..)
import Models.EntityTree
import Page
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.List


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


getMaybeEntityIdAtCursor model =
    model.entityListCursor.maybeEntityIdAtCursor


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    }


createEntityListForCurrentView model =
    Page.maybeGetEntityListPage model
        ?|> (Models.EntityTree.createEntityTreeFromEntityListPageModel # model >> Entity.Tree.flatten)
        ?= []



--computeMaybeNewEntityIdAtCursor : SubModel model -> Maybe EntityId


computeMaybeNewEntityIdAtCursor model =
    let
        newEntityIdList =
            createEntityListForCurrentView model
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor focusableEntityId =
            ( model.entityListCursor.entityIdList, newEntityIdList )
                |> Tuple2.mapBoth (X.List.firstIndexOf focusableEntityId)
                |> (\( maybeOldIndex, maybeNewIndex ) ->
                        case ( maybeOldIndex, maybeNewIndex, focusableEntityId ) of
                            ( Just oldIndex, Just newIndex, TodoId _ ) ->
                                case compare oldIndex newIndex of
                                    LT ->
                                        computeMaybeFEI oldIndex

                                    GT ->
                                        computeMaybeFEI (oldIndex + 1)

                                    EQ ->
                                        Nothing

                            ( Just oldIndex, Nothing, _ ) ->
                                computeMaybeFEI oldIndex

                            _ ->
                                Nothing
                   )
    in
    model.entityListCursor.maybeEntityIdAtCursor
        ?+> computeNewEntityIdAtCursor
