module Models.Stores exposing (..)

import Data.TodoDoc as TodoDoc exposing (TodoDoc)
import GroupDoc exposing (GroupDoc, GroupDocType(..))
import Models.GroupDocStore as GDStore exposing (HasGroupDocStores)
import Store
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Predicate


getActiveTodoListHavingActiveContext model =
    model.todoStore
        |> Store.filterDocs
            (allPass
                [ TodoDoc.isActive
                , todoGroupDocActivePredicate ContextGroupDocType model
                ]
            )


getActiveTodoListHavingActiveProject model =
    model.todoStore
        |> Store.filterDocs
            (allPass
                [ TodoDoc.isActive
                , todoGroupDocActivePredicate ProjectGroupDocType model
                ]
            )


todoGroupDocActivePredicate : GroupDocType -> HasGroupDocStores a -> (TodoDoc -> Bool)
todoGroupDocActivePredicate gdType model =
    let
        match =
            GDStore.getActiveDocIdSet gdType model
                |> TodoDoc.hasGroupDocIdInSet gdType
    in
    \todoDoc -> match todoDoc


allTodoGroupDocActivePredicate : HasGroupDocStores a -> (TodoDoc -> Bool)
allTodoGroupDocActivePredicate model =
    let
        match =
            X.Predicate.all
                [ todoGroupDocActivePredicate ProjectGroupDocType model
                , todoGroupDocActivePredicate ContextGroupDocType model
                ]
    in
    \todoDoc -> match todoDoc
