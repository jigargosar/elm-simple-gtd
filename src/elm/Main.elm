module Main exposing (..)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusInputCmd, focusSelectorIfNoFocusCmd)
import Entity.Main
import ExclusiveMode
import Entity
import Firebase.Main
import X.Debug
import X.Keyboard as Keyboard exposing (Key)
import X.Record as Record exposing (set)
import X.Return as Return
import Firebase
import Http
import Keyboard.Combo
import LaunchBar
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Model as Model
import Notification exposing (Response)
import Todo.Notification.Model
import Routes
import Store
import Todo
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Return
import RouteUrl exposing (RouteUrlProgram)
import Task
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Model exposing (..)
import Todo.Main
import View
import Json.Decode as D exposing (Decoder)
import LaunchBar.Main
import Update


main : RouteUrlProgram Flags Model Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = Model.init
        , update = Update.update
        , view = View.init
        , subscriptions = subscriptions
        }


type alias Return =
    Return.Return Msg Model


type alias ReturnTuple a =
    Return.Return Msg ( a, Model )


type alias ReturnF =
    Return -> Return


subscriptions : Model -> Sub Model.Msg
subscriptions m =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) OnNowChanged
            , Keyboard.subscription OnKeyboardMsg
            , Keyboard.ups OnGlobalKeyUp
            , Store.onChange OnPouchDBChange
            , Firebase.onChange OnFirebaseDatabaseChange
            ]
            |> Sub.map OnSubMsg
        , Keyboard.Combo.subscriptions m.keyComboModel
        , Todo.Main.subscriptions m
        ]
