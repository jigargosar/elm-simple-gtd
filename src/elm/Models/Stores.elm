module Models.Stores exposing (..)

import Data.TodoDoc as TodoDoc
import GroupDoc exposing (GroupDocType(..))
import Models.GroupDocStore as GDStore exposing (..)
import Store
import X.Function exposing (..)
import X.Function.Infix exposing (..)


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


todoProjectActiveFilter model =
    GDStore.getActiveDocs ProjectGroupDocType model


todoContextActiveFilter model =
    1
