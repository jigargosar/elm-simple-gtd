module Models.Stores exposing (..)

import Data.TodoDoc as TodoDoc exposing (TodoDoc)
import GroupDoc exposing (GroupDoc, GroupDocType(..))
import Models.GroupDocStore as GDStore exposing (HasGroupDocStores)
import Store
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import X.Predicate


isTodoContextActive model =
    TodoDoc.getContextId
        >> GDStore.findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    TodoDoc.getProjectId
        >> GDStore.findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ TodoDoc.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
    model.todoStore |> Store.filterDocs (allPass [ TodoDoc.isActive, isTodoProjectActive model ])


todoGroupDocActivePredicate : GroupDocType -> HasGroupDocStores a -> (TodoDoc -> Bool)
todoGroupDocActivePredicate gdType model =
    let
        activeProjectIdSet =
            GDStore.getActiveDocIdSet gdType model
    in
    TodoDoc.hasGroupDocIdInSet gdType activeProjectIdSet


allTodoGroupDocActivePredicate : HasGroupDocStores a -> (TodoDoc -> Bool)
allTodoGroupDocActivePredicate model =
    let
        _ =
            1
    in
    X.Predicate.all
        [ todoGroupDocActivePredicate ProjectGroupDocType model
        , todoGroupDocActivePredicate ContextGroupDocType model
        ]
