port module Main exposing (..)

import AppDrawer.Main
import Firebase
import Firebase.Main
import Keyboard.Combo
import Model
import Return
import RouteUrl
import Routes
import Store
import Time
import Todo.Main
import Update
import View
import X.Keyboard
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Msg


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)


main : RouteUrl.RouteUrlProgram Model.Flags Model.Model Msg.Msg
main =
    let
        _ =
            1
    in
        RouteUrl.programWithFlags
            { delta2url = Routes.delta2hash
            , location2messages = Routes.hash2messages
            , init = Model.init
            , update = Update.update
            , view = View.init
            , subscriptions = subscriptions
            }


subscriptions : Model.Model -> Sub Msg.Msg
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
