module Update.Config exposing (..)

import Msg exposing (AppMsg)
import Todo.Msg exposing (TodoMsg)
import TodoMsg


--updateConfig : AppModel -> UpdateConfig AppMsg


updateConfig model =
    { noop = Msg.noop
    , onStartAddingTodoToInbox = TodoMsg.onStartAddingTodoToInbox
    , onStartAddingTodoWithFocusInEntityAsReference =
        TodoMsg.onStartAddingTodoWithFocusInEntityAsReference
    , openLaunchBarMsg = Msg.openLaunchBarMsg
    , afterTodoUpsert = TodoMsg.afterTodoUpsert
    , onSetExclusiveMode = Msg.onSetExclusiveMode
    , revertExclusiveMode = Msg.revertExclusiveMode
    , switchToEntityListViewTypeMsg = Msg.switchToEntityListViewTypeMsg
    , setDomFocusToFocusInEntityCmd = Msg.setDomFocusToFocusInEntityCmd
    , onStartEditingTodo = TodoMsg.onStartEditingTodo
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onStartSetupAddTodo = TodoMsg.onStartSetupAddTodo
    , setFocusInEntityWithEntityId = Msg.setFocusInEntityWithEntityIdMsg
    , setFocusInEntityMsg = Msg.setFocusInEntityMsg
    , saveTodoForm = Msg.onSaveTodoForm
    , saveGroupDocForm = Msg.onSaveGroupDocForm
    , onTodoMsgWithNow = Msg.OnTodoMsgWithNow
    , onLaunchBarMsgWithNow = Msg.OnLaunchBarMsgWithNow
    , onMdl = Msg.OnMdl
    , bringEntityIdInViewMsg = Msg.bringEntityIdInViewMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> Msg.OnTodoMsg
    , entityListFocusPreviousEntityMsg = Msg.entityListFocusPreviousEntityMsg
    , entityListFocusNextEntityMsg = Msg.entityListFocusNextEntityMsg
    }
