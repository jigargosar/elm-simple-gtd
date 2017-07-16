module Model.Stores exposing (..)

import GroupDoc
import Model.GroupDocStore exposing (..)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
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
