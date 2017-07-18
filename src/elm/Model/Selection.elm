module Model.Selection
    exposing
        ( clearSelection
        , setSelectedEntityIdSet
        , updateSelectedEntityIdSet
        )

import Set exposing (Set)


clearSelection =
    setSelectedEntityIdSet Set.empty



--getSelectedEntityIdSet : AppModel -> Set DocId
{-
   getSelectedEntityIdSet =
       (.selectedEntityIdSet)
-}
--setSelectedEntityIdSet : Set DocId -> ModelF


setSelectedEntityIdSet selectedEntityIdSet model =
    { model | selectedEntityIdSet = selectedEntityIdSet }



--updateSelectedEntityIdSet : (Set DocId -> Set DocId) -> ModelF


updateSelectedEntityIdSet updater model =
    setSelectedEntityIdSet (updater model.selectedEntityIdSet) model
