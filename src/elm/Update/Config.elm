module Update.Config exposing (..)

import LaunchBar.Messages
import Lazy
import Material
import Model.EntityList
import Msg exposing (AppMsg)
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import TodoMsg
import Types exposing (AppModel)
import Update.AppHeader
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.LaunchBar
import Update.Subscription
import Update.Todo
import Update.ViewType


type alias UpdateConfig msg =
    Update.LaunchBar.Config msg
        (Update.AppHeader.Config msg
            (Update.ExclusiveMode.Config msg
                (Update.ViewType.Config msg
                    (Update.Firebase.Config msg
                        (Update.CustomSync.Config msg
                            (Update.Entity.Config msg
                                (Update.Subscription.Config msg
                                    (Update.Todo.Config msg
                                        { onTodoMsgWithNow : TodoMsg -> Time -> msg
                                        , onLaunchBarMsgWithNow : LaunchBar.Messages.LaunchBarMsg -> Time -> msg
                                        , onMdl : Material.Msg msg -> msg
                                        }
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )


updateConfig : AppModel -> UpdateConfig AppMsg
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
    , currentViewEntityList =
        Lazy.lazy (\_ -> Model.EntityList.createEntityListForCurrentView model)
    , saveTodoForm = Msg.onSaveTodoForm
    , saveGroupDocForm = Msg.onSaveGroupDocForm
    , onTodoMsgWithNow = Msg.OnTodoMsgWithNow
    , onLaunchBarMsgWithNow = Msg.OnLaunchBarMsgWithNow
    , onMdl = Msg.OnMdl
    , bringEntityIdInViewMsg = Msg.bringEntityIdInViewMsg
    , onGotoRunningTodoMsg = Todo.Msg.onGotoRunningTodoMsg |> Msg.OnTodoMsg
    }
