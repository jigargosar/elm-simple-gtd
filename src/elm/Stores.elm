module Stores exposing (..)

import Document
import Entity
import Entity.Tree
import Entity.Types exposing (..)
import EntityId
import Model.EntityTree
import Model.GroupDocStore exposing (..)
import Model.Todo exposing (..)
import Model.ViewType
import Return exposing (andThen)
import Store
import Todo
import Todo.Types exposing (TodoAction(TA_AutoSnooze), TodoDoc, TodoStore)
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import X.Record exposing (maybeOverT2, maybeSetIn, overT2, set, setIn)
import Set
import Tuple2
import X.List


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
                            setFocusInIndex (oldIndex)

                        GT ->
                            setFocusInIndex (oldIndex + 1)

                        EQ ->
                            identity
            in
                model
                    |> case indexTuple of
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
    in
        ( oldModel, newModel )
            |> Tuple2.mapBoth
                (createEntityListForCurrentView >> (getMaybeFocusInEntityIndex # oldModel))
            |> updateEntityListCursorFromEntityIndexTuple newModel


updateEntityListCursorOnGroupDocChange =
    updateEntityListCursor False


updateEntityListCursorOnTodoChange =
    updateEntityListCursor True


getMaybeFocusInEntityIndex entityList model =
    entityList
        |> List.findIndex (Entity.equalById model.focusInEntity)


createEntityListForCurrentView model =
    Model.ViewType.maybeGetEntityListViewType model
        ?|> (Model.EntityTree.createEntityTreeForViewType # model >> Entity.Tree.flatten)
        ?= []



{- setFocusInEntityWithTodoId : DocId -> AppModelF -}


setFocusInEntityWithTodoId =
    EntityId.fromTodoDocId >> setFocusInEntityWithEntityId


setFocusInEntity entity =
    set focusInEntity entity


setFocusInEntityWithEntityId entityId model =
    findByEntityId entityId model
        ?|> setIn model focusInEntity
        ?= model


findByEntityId entityId =
    case entityId of
        ContextId id ->
            findContextById id >>? createContextEntity

        ProjectId id ->
            findProjectById id >>? createProjectEntity

        TodoId id ->
            findTodoById id >>? createTodoEntity
