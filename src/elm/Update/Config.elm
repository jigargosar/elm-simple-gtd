module Update.Config exposing (..)

import Msg exposing (AppMsg)
import Todo.Msg exposing (TodoMsg)
import Types.AppModel exposing (AppModel)
import Update.Types exposing (UpdateConfig)


updateConfig : AppModel -> UpdateConfig AppMsg
updateConfig model =
    { noop = Msg.noop
    , onStartAddingTodoToInbox = Todo.Msg.onStartAddingTodoToInbox |> Msg.OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        Todo.Msg.onStartAddingTodoWithFocusInEntityAsReference |> Msg.OnTodoMsg
    , openLaunchBarMsg = Msg.openLaunchBarMsg
    , afterTodoUpsert = Todo.Msg.afterTodoUpsert >> Msg.OnTodoMsg
    , onSetExclusiveMode = Msg.onSetExclusiveMode
    , revertExclusiveMode = Msg.revertExclusiveMode
    , switchToEntityListPageMsg = Msg.switchToEntityListPageMsg
    , setDomFocusToFocusInEntityCmd = Msg.setDomFocusToFocusInEntityCmd
    , onStartEditingTodo = Todo.Msg.onStartEditingTodo >> Msg.OnTodoMsg
    , onSaveExclusiveModeForm = Msg.onSaveExclusiveModeForm
    , onStartSetupAddTodo = Todo.Msg.onStartSetupAddTodo |> Msg.OnTodoMsg
    , setFocusInEntityWithEntityId = Msg.setFocusInEntityWithEntityIdMsg
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
