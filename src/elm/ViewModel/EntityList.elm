module ViewModel.EntityList exposing (..)

import Data.EntityTree
import Entity
import EntityId
import GroupDoc.ViewModel
import List.Extra as List
import Maybe.Extra as Maybe
import Pages.EntityList as EntityList
import Todo.ViewModel
import Toolkit.Operators exposing (..)
import X.Function exposing (..)


pageVM config model pageModel =
    let
        entityTree =
            EntityList.createEntityTree pageModel model

        maybeCursorEntityId =
            let
                entityList =
                    Data.EntityTree.flatten entityTree
            in
            EntityList.getMaybeLastKnownFocusedEntityId pageModel
                ?+> (Entity.hasId >> List.find # entityList)
                |> Maybe.orElse (List.head entityList)
                ?|> Entity.toEntityId

        isCursorAtEntityId entityId =
            maybeCursorEntityId ?|> equals entityId ?= False

        getTabIndexForEntityId entityId =
            if isCursorAtEntityId entityId then
                0
            else
                -1

        createTodoViewModel todo =
            let
                isFocusable =
                    EntityId.fromTodo todo |> isCursorAtEntityId
            in
            todo
                |> Todo.ViewModel.createTodoViewModel
                    config
                    EntityList.getEntityListDomIdFromEntityId
                    model
                    isFocusable
    in
    { createProjectGroupVM = GroupDoc.ViewModel.createProjectGroupVM config getTabIndexForEntityId
    , createContextGroupVM = GroupDoc.ViewModel.createContextGroupVM config getTabIndexForEntityId
    , createTodoViewModel = createTodoViewModel
    , entityTree = entityTree
    }
