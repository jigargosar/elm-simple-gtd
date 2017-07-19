module Update.Types exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity, EntityId, EntityListViewType)
import ExclusiveMode.Types exposing (ExclusiveMode)
import GroupDoc.FormTypes exposing (GroupDocForm)
import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import Lazy exposing (Lazy)
import Return
import Time exposing (Time)
import Todo.FormTypes exposing (TodoForm)
import Todo.Types exposing (TodoDoc)


type alias ReturnF msg model =
    Return.ReturnF msg model


type alias UpdateConfig =
    { --model
      now : Time
    , activeProjects : List ProjectDoc
    , activeContexts : List ContextDoc
    , updateEntityListCursorOnTodoChange : ReturnF msg model
    , updateEntityListCursorOnGroupDocChange : ReturnF msg model
    , currentViewEntityListLazy : Lazy (List Entity)

    --msg
    , clearSelection : ReturnF msg model
    , noop : ReturnF msg model
    , openLaunchBarMsg : ReturnF msg model
    , revertExclusiveMode : ReturnF msg model
    , setDomFocusToFocusInEntityCmd : ReturnF msg model
    , onSaveTodoForm : TodoForm -> ReturnF msg model
    , onSaveGroupDocForm : GroupDocForm -> ReturnF msg model
    , onSetExclusiveMode : ExclusiveMode -> ReturnF msg model
    , onSaveExclusiveModeForm : ReturnF msg model
    , onToggleContextArchived : DocId -> ReturnF msg model
    , onToggleContextDeleted : DocId -> ReturnF msg model
    , onToggleProjectArchived : DocId -> ReturnF msg model
    , onToggleProjectDeleted : DocId -> ReturnF msg model
    , switchToContextsView : ReturnF msg model
    , setFocusInEntityWithEntityId : EntityId -> ReturnF msg model
    , setFocusInEntity : Entity -> ReturnF msg model
    , closeNotification : String -> ReturnF msg model
    , onStartSetupAddTodo : ReturnF msg model
    , onSwitchToNewUserSetupModeIfNeeded : ReturnF msg model
    , onPersistLocalPref : ReturnF msg model

    -- todo msg
    , afterTodoUpsert : TodoDoc -> ReturnF msg model
    , onStartAddingTodoWithFocusInEntityAsReference : ReturnF msg model
    , onStartAddingTodoToInbox : ReturnF msg model
    , onToggleTodoArchived : DocId -> ReturnF msg model
    , onToggleTodoDeleted : DocId -> ReturnF msg model
    , switchToEntityListView : EntityListViewType -> ReturnF msg model
    , onStartEditingTodo : TodoDoc -> ReturnF msg model
    }
