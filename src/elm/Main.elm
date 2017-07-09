port module Main exposing (..)

import AppDrawer.Main
import Firebase.Main
import Keyboard.Combo
import Model
import RouteUrl
import Routes
import Store
import Time
import Todo.Main
import Update
import View
import X.Keyboard
import Json.Encode as E
import Msg
import Types exposing (AppModel)


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)


main : RouteUrl.RouteUrlProgram Model.Flags AppModel Msg.Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = Model.init
        , update = Update.update
        , view = View.init
        , subscriptions = subscriptions
        }


subscriptions : AppModel -> Sub Msg.Msg
subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Msg.OnNowChanged
            , X.Keyboard.subscription Msg.OnKeyboardMsg
            , X.Keyboard.ups Msg.OnGlobalKeyUp
            , Store.onChange Msg.OnPouchDBChange
            , onFirebaseDatabaseChangeSub Msg.OnFirebaseDatabaseChange
            ]
            |> Sub.map Msg.OnSubMsg
        , Keyboard.Combo.subscriptions model.keyComboModel
        , Todo.Main.subscriptions model
        , Firebase.Main.subscriptions model
        , AppDrawer.Main.subscriptions model
        ]
