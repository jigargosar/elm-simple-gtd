module Model.Stores exposing (..)

import GroupDoc
import Model.GroupDocStore exposing (..)
import Todo
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Store


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
