module Models.Selection
    exposing
        ( clearSelection
        , setSelectedEntityIdSet
        , updateSelectedEntityIdSet
        )

import Set exposing (Set)


clearSelection =
    setSelectedEntityIdSet Set.empty


setSelectedEntityIdSet selectedEntityIdSet model =
    { model | selectedEntityIdSet = selectedEntityIdSet }


updateSelectedEntityIdSet updater model =
    setSelectedEntityIdSet (updater model.selectedEntityIdSet) model
