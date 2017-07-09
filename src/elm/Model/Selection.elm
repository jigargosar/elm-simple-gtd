module Model.Selection exposing (..)

import Document.Types exposing (DocId)
import Set exposing (Set)
import Types exposing (AppModel, ModelF)


clearSelection =
    setSelectedEntityIdSet Set.empty


getSelectedEntityIdSet : AppModel -> Set DocId
getSelectedEntityIdSet =
    (.selectedEntityIdSet)


setSelectedEntityIdSet : Set DocId -> ModelF
setSelectedEntityIdSet selectedEntityIdSet model =
    { model | selectedEntityIdSet = selectedEntityIdSet }


updateSelectedEntityIdSet : (Set DocId -> Set DocId) -> ModelF
updateSelectedEntityIdSet updater model =
    setSelectedEntityIdSet (updater (getSelectedEntityIdSet model)) model
