module Update.Config exposing (..)

import Lazy
import Model
import Model.EntityList
import Model.GroupDocStore
import Model.Selection exposing (clearSelection)
import Model.Stores
import Msg
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Return exposing (map)
import TodoMsg


updateConfig andThenUpdate model =
    { --model
      now = model.now
    , activeProjects = (Model.GroupDocStore.getActiveProjects model)
    , activeContexts = (Model.GroupDocStore.getActiveContexts model)
    , updateEntityListCursorOnTodoChange = map (Model.EntityList.updateEntityListCursorOnTodoChange model)
    , updateEntityListCursorOnGroupDocChange =
        map (Model.EntityList.updateEntityListCursorOnGroupDocChange model)
    , currentViewEntityListLazy =
        Lazy.lazy
            (\_ ->
                Model.EntityList.createEntityListForCurrentView model
            )

    --msg
    , clearSelection = map Model.Selection.clearSelection
    , noop = andThenUpdate Msg.noop
    , openLaunchBarMsg = andThenUpdate Msg.openLaunchBarMsg
    , revertExclusiveMode = andThenUpdate Msg.revertExclusiveMode
    , setDomFocusToFocusInEntityCmd = andThenUpdate Msg.setDomFocusToFocusInEntityCmd
    , onSaveTodoForm = Msg.onSaveTodoForm >> andThenUpdate
    , onSaveGroupDocForm = Msg.onSaveGroupDocForm >> andThenUpdate
    , onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm |> andThenUpdate
    , onToggleContextArchived = Msg.onToggleContextArchived >> andThenUpdate
    , onToggleContextDeleted = Msg.onToggleContextDeleted >> andThenUpdate
    , onToggleProjectArchived = Msg.onToggleProjectArchived >> andThenUpdate
    , onToggleProjectDeleted = Msg.onToggleProjectDeleted >> andThenUpdate
    , switchToContextsView = Msg.switchToContextsView |> andThenUpdate
    , setFocusInEntityWithEntityId =
        (\entityId ->
            map (Model.Stores.setFocusInEntityWithEntityId entityId)
                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
        )
    , setFocusInEntity =
        (\entity ->
            map (Model.setFocusInEntity entity)
                >> andThenUpdate Msg.setDomFocusToFocusInEntityCmd
        )
    , closeNotification = Msg.OnCloseNotification >> andThenUpdate
    , onStartSetupAddTodo = andThenUpdate TodoMsg.onStartSetupAddTodo
    , onSwitchToNewUserSetupModeIfNeeded =
        andThenUpdate Msg.onSwitchToNewUserSetupModeIfNeeded
    , onPersistLocalPref = andThenUpdate Msg.onPersistLocalPref

    -- todo msg
    , afterTodoUpsert = TodoMsg.afterTodoUpsert >> andThenUpdate
    , onStartAddingTodoWithFocusInEntityAsReference =
        andThenUpdate TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , onStartAddingTodoToInbox = andThenUpdate TodoMsg.onStartAddingTodoToInbox
    , onToggleTodoArchived = TodoMsg.onToggleDoneAndMaybeSelection >> andThenUpdate
    , onToggleTodoDeleted = TodoMsg.onToggleDeletedAndMaybeSelection >> andThenUpdate
    , switchToEntityListView = Msg.switchToEntityListView >> andThenUpdate
    , onStartEditingTodo = TodoMsg.onStartEditingTodo >> andThenUpdate
    }
