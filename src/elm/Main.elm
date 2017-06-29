module Main exposing (..)

import Firebase
import Keyboard.Combo
import Model exposing (Flags)
import Return
import RouteUrl exposing (RouteUrlProgram)
import Routes
import Store
import Time
import Todo.Main
import Update
import View
import X.Keyboard


main : RouteUrlProgram Flags Model.Model Model.Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = Model.init
        , update = Update.update
        , view = View.init
        , subscriptions = subscriptions2
        }


subscriptions2 : Model.Model -> Sub Model.Msg
subscriptions2 m =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Model.OnNowChanged
            , X.Keyboard.subscription Model.OnKeyboardMsg
            , X.Keyboard.ups Model.OnGlobalKeyUp
            , Store.onChange Model.OnPouchDBChange
            , Firebase.onChange Model.OnFirebaseDatabaseChange
            ]
            |> Sub.map Model.OnSubMsg
        , Keyboard.Combo.subscriptions m.keyComboModel
        , Todo.Main.subscriptions m
        ]
