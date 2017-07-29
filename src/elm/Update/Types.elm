module Update.Types exposing (..)

import LaunchBar.Messages
import Material
import Time exposing (Time)
import Todo.Msg exposing (TodoMsg)
import Update.AppHeader
import Update.CustomSync
import Update.Entity
import Update.ExclusiveMode
import Update.Firebase
import Update.LaunchBar
import Update.Page
import Update.Subscription
import Update.Todo


type alias UpdateConfig msg =
    Update.LaunchBar.Config msg
        (Update.AppHeader.Config msg
            (Update.ExclusiveMode.Config msg
                (Update.Page.Config msg
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
