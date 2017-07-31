module EntityListCursor exposing (..)

import Entity
import Entity.Tree
import Entity.Types exposing (..)
import Models.EntityTree
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.List


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursorOld : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


getMaybeEntityIdAtCursor__ model =
    model.entityListCursor.maybeEntityIdAtCursorOld


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeEntityIdAtCursorOld = Nothing
    }


createEntityListFormMaybeEntityListPageModelOld maybeEntityListPageModel model =
    maybeEntityListPageModel
        ?|> (Models.EntityTree.createEntityTreeFromEntityListPageModel # model >> Entity.Tree.flatten)
        ?= []


computeMaybeNewEntityIdAtCursorOld maybeEntityListPageModel model =
    let
        newEntityIdList =
            createEntityListFormMaybeEntityListPageModelOld maybeEntityListPageModel model
                .|> Entity.toEntityId

        computeMaybeFEI index =
            X.List.clampAndGetAtIndex index newEntityIdList

        computeNewEntityIdAtCursor entityIdAtCursor =
            ( model.entityListCursor.entityIdList, newEntityIdList )
                |> Tuple2.mapBoth (X.List.firstIndexOf entityIdAtCursor)
                |> (\( maybeOldIndex, maybeNewIndex ) ->
                        case ( maybeOldIndex, maybeNewIndex, entityIdAtCursor ) of
                            ( Just oldIndex, Just newIndex, TodoId _ ) ->
                                case compare oldIndex newIndex of
                                    LT ->
                                        computeMaybeFEI oldIndex

                                    GT ->
                                        computeMaybeFEI (oldIndex + 1)

                                    EQ ->
                                        Just entityIdAtCursor

                            ( Just oldIndex, Nothing, _ ) ->
                                computeMaybeFEI oldIndex

                            _ ->
                                Just entityIdAtCursor
                   )
    in
    model.entityListCursor.maybeEntityIdAtCursorOld
        ?|> computeNewEntityIdAtCursor
        ?= List.head newEntityIdList
