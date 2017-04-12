module View.Context exposing (..)

import Context
import Dict
import Html exposing (Html)
import Model.Types exposing (EntityAction(Delete, StartEditing), Entity(ContextEntity), MainViewType(ContextView))
import Msg exposing (Msg)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model
import Todo
import View.Entity


vmList : Model.Types.Model -> List View.Entity.ViewModel
vmList model =
    let
        todoByGroupIdDict =
            Model.getActiveTodoListGroupedByContextId model
    in
        Model.getActiveContexts model
            |> (::) Context.null
            .|> View.Entity.createVM todoByGroupIdDict
                    { createEntity = ContextEntity
                    , getId = Context.getId
                    , isNull = Context.isNull
                    , getName = Context.getName
                    , getViewType = ContextView
                    }
