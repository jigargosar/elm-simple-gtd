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


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)


main : RouteUrl.RouteUrlProgram Model.Flags Model.Model Model.Msg
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


subscriptions : Model.Model -> Sub Model.Msg
subscriptions model =
    Sub.batch
        [ Sub.batch
            [ Time.every (Time.second * 1) Model.OnNowChanged
            , X.Keyboard.subscription Model.OnKeyboardMsg
            , X.Keyboard.ups Model.OnGlobalKeyUp
            , Store.onChange Model.OnPouchDBChange
            , onFirebaseDatabaseChangeSub Model.OnFirebaseDatabaseChange
            ]
            |> Sub.map Model.OnSubMsg
        , Keyboard.Combo.subscriptions model.keyComboModel
        , Todo.Main.subscriptions model
        , Firebase.Main.subscriptions model
        , AppDrawer.Main.subscriptions model
        ]
