module Models.Stores exposing (..)

import Data.TodoDoc
import Entity exposing (..)
import GroupDoc
import Models.GroupDocStore exposing (..)
import Models.TodoDocStore as TodoDocStore
import Store
import X.Function exposing (..)
import X.Function.Infix exposing (..)


isTodoContextActive model =
    Data.TodoDoc.getContextId
        >> Models.GroupDocStore.findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    Data.TodoDoc.getProjectId
        >> Models.GroupDocStore.findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ Data.TodoDoc.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
    model.todoStore |> Store.filterDocs (allPass [ Data.TodoDoc.isActive, isTodoProjectActive model ])


findByEntityId entityId =
    case entityId of
        ContextEntityId id ->
            findContextById id >>? createContextEntity

        ProjectEntityId id ->
            findProjectById id >>? createProjectEntity

        TodoEntityId id ->
            TodoDocStore.findTodoById id >>? createTodoEntity
