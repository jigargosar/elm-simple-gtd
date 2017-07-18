module Update.Internal exposing (..)

import Entity.Types exposing (EntityMsg)
import Lazy
import Model.EntityList
import Model.Stores
import Msg.CustomSync exposing (CustomSyncMsg)
import Msg.GroupDoc exposing (GroupDocMsg)
import TodoMsg
import Update.Entity
import LaunchBar.Messages exposing (LaunchBarMsg)
import Model
import Model.GroupDocStore
import Model.Selection
import Msg exposing (..)
import Msg.ViewType exposing (ViewTypeMsg(SwitchToContextsView))
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import Types exposing (AppModel)
import Update.CustomSync
import Update.LaunchBar
import Update.ViewType
import X.Return as Return exposing (returnWith, returnWithNow)
import Return exposing (andThen, command, map)
import Update.Todo
import Types exposing (..)
import Msg
import Update.GroupDoc
import Toolkit.Operators exposing (..)


type alias ReturnF =
    Return.ReturnF AppMsg AppModel


type alias AndThenUpdate =
    AppMsg -> ReturnF


onViewTypeMsg : AndThenUpdate -> ViewTypeMsg -> ReturnF
onViewTypeMsg andThenUpdate msg =
    let
        config : Update.ViewType.Config AppMsg AppModel
        config =
            { clearSelection = map Model.Selection.clearSelection }
    in
        Update.ViewType.update config msg


onLaunchBarMsgWithNow : AndThenUpdate -> LaunchBarMsg -> Time -> ReturnF
onLaunchBarMsgWithNow andThenUpdate msg now =
    let
        createConfig : AppModel -> Update.LaunchBar.Config AppMsg AppModel
        createConfig model =
            { now = now
            , activeProjects = (Model.GroupDocStore.getActiveProjects model)
            , activeContexts = (Model.GroupDocStore.getActiveContexts model)
            , onComplete = Msg.revertExclusiveMode |> andThenUpdate
            , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
            , onSwitchView = Msg.switchToEntityListView >> andThenUpdate
            }
    in
        returnWith createConfig (Update.LaunchBar.update # msg)


onTodoMsgWithNow : AndThenUpdate -> TodoMsg -> Time -> ReturnF
onTodoMsgWithNow andThenUpdate msg now =
    let
        config : AppModel -> Update.Todo.Config AppMsg AppModel
        config model =
            { switchToContextsView = Msg.switchToContextsViewMsg |> andThenUpdate
            , setFocusInEntityWithEntityId =
                -- later: create and move focusInEntity related methods to corresponding update
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
            , afterTodoUpdate = Msg.revertExclusiveMode |> andThenUpdate
            , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
            , currentViewEntityList = Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
            }
    in
        returnWith identity
            (\oldModel ->
                Update.Todo.update (config oldModel) now msg
                    >> map (Model.EntityList.updateEntityListCursorOnTodoChange oldModel)
            )


onEntityMsg : AndThenUpdate -> EntityMsg -> ReturnF
onEntityMsg andThenUpdate msg =
    let
        config : Update.Entity.Config AppMsg AppModel
        config =
            { onSetExclusiveMode = Msg.onSetExclusiveMode >> andThenUpdate
            , revertExclusiveMode = Msg.revertExclusiveMode |> andThenUpdate
            , onToggleContextArchived = Msg.onToggleContextArchived >> andThenUpdate
            , onToggleContextDeleted = Msg.onToggleContextDeleted >> andThenUpdate
            , onToggleProjectArchived = Msg.onToggleProjectArchived >> andThenUpdate
            , onToggleProjectDeleted = Msg.onToggleProjectDeleted >> andThenUpdate
            , onToggleTodoArchived = TodoMsg.onToggleDone >> andThenUpdate
            , onToggleTodoDeleted = TodoMsg.onToggleDeleted >> andThenUpdate
            , switchToEntityListView = Msg.switchToEntityListView >> andThenUpdate
            , setDomFocusToFocusInEntityCmd =
                Msg.setDomFocusToFocusInEntityCmd |> andThenUpdate
            , onStartEditingTodo = TodoMsg.onStartEditingTodo >> andThenUpdate
            }
    in
        Update.Entity.update config msg


onCustomSyncMsg : AndThenUpdate -> CustomSyncMsg -> ReturnF
onCustomSyncMsg andThenUpdate msg =
    let
        config : Update.CustomSync.Config AppMsg AppModel
        config =
            { saveXModeForm = Msg.onSaveExclusiveModeForm |> andThenUpdate
            , setXMode = Msg.onSetExclusiveMode >> andThenUpdate
            }
    in
        Update.CustomSync.update config msg


onGroupDocMsg : GroupDocMsg -> ReturnF
onGroupDocMsg msg =
    returnWith identity
        (\oldModel ->
            Update.GroupDoc.update msg
                >> map (Model.EntityList.updateEntityListCursorOnGroupDocChange oldModel)
        )
