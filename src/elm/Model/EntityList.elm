module Model.EntityList exposing (..)

import Entity
import Entity.Tree
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (focusInEntity)
import Model.EntityTree
import Model.ViewType
import Toolkit.Operators exposing (..)
import Tuple2
import X.List
import X.Record exposing (maybeSetIn)


createEntityListForCurrentView model =
    Model.ViewType.maybeGetEntityListViewType model
        ?|> (Model.EntityTree.createEntityTreeForViewType # model >> Entity.Tree.flatten)
        ?= []


updateEntityListCursor focusNextOnIndexChange oldModel newModel =
    let
        updateEntityListCursorFromEntityIndexTuple model indexTuple =
            let
                setFocusInEntityByIndex index entityList model =
                    X.List.clampIndex index entityList
                        |> (List.getAt # entityList)
                        |> Maybe.orElse (List.head entityList)
                        |> maybeSetIn model focusInEntity

                setFocusInIndex index =
                    setFocusInEntityByIndex
                        index
                        (createEntityListForCurrentView model)

                focusNext oldIndex newIndex =
                    case compare oldIndex newIndex of
                        LT ->
                            setFocusInIndex oldIndex

                        GT ->
                            setFocusInIndex (oldIndex + 1)

                        EQ ->
                            identity
            in
            model
                |> (case indexTuple of
                        -- note we want focus to remain on group entity, when edited, since its sort order may change. But if removed from view, we want to focus on next entity.
                        ( Just oldIndex, Just newIndex ) ->
                            if focusNextOnIndexChange then
                                focusNext oldIndex newIndex
                            else
                                identity

                        ( Just oldIndex, Nothing ) ->
                            setFocusInIndex oldIndex

                        _ ->
                            identity
                   )

        getMaybeFocusInEntityIndex entityList model =
            entityList
                |> List.findIndex (Entity.equalById model.focusInEntity)
    in
    ( oldModel, newModel )
        |> Tuple2.mapBoth
            (createEntityListForCurrentView >> (getMaybeFocusInEntityIndex # oldModel))
        |> updateEntityListCursorFromEntityIndexTuple newModel


updateEntityListCursorOnGroupDocChange =
    updateEntityListCursor False


updateEntityListCursorOnTodoChange =
    updateEntityListCursor True
