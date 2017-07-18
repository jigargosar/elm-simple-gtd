module Model.Stores exposing (..)

import Entity.Types exposing (..)
import EntityId
import GroupDoc
import Model
import Model.GroupDocStore exposing (..)
import Model.Todo exposing (findTodoById)
import Todo
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Store
import X.Record exposing (setIn)


isTodoContextActive model =
    Todo.getContextId
        >> Model.GroupDocStore.findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    Todo.getProjectId
        >> Model.GroupDocStore.findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoProjectActive model ])


findByEntityId entityId =
    case entityId of
        ContextId id ->
            findContextById id >>? createContextEntity

        ProjectId id ->
            findProjectById id >>? createProjectEntity

        TodoId id ->
            findTodoById id >>? createTodoEntity


setFocusInEntityWithEntityId entityId =
    applyMaybeWith (findByEntityId entityId) Model.setFocusInEntity
