module Models.Stores exposing (..)

import Entity exposing (..)
import GroupDoc
import Models.GroupDocStore exposing (..)
import Models.Todo exposing (findTodoById)
import Store
import TodoDoc
import X.Function exposing (..)
import X.Function.Infix exposing (..)


isTodoContextActive model =
    TodoDoc.getContextId
        >> Models.GroupDocStore.findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    TodoDoc.getProjectId
        >> Models.GroupDocStore.findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ TodoDoc.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
    model.todoStore |> Store.filterDocs (allPass [ TodoDoc.isActive, isTodoProjectActive model ])


findByEntityId entityId =
    case entityId of
        ContextId id ->
            findContextById id >>? createContextEntity

        ProjectId id ->
            findProjectById id >>? createProjectEntity

        TodoId id ->
            findTodoById id >>? createTodoEntity
