module Models.Stores exposing (..)

import Data.TodoDoc
import Entity exposing (..)
import GroupDoc
import Models.GroupDocStore exposing (..)
import Models.Todo exposing (findTodoById)
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
        ContextId id ->
            findContextById id >>? createContextEntity

        ProjectId id ->
            findProjectById id >>? createProjectEntity

        TodoId id ->
            findTodoById id >>? createTodoEntity
