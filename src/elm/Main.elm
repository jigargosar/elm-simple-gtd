port module Main exposing (..)

import AppDrawer.Main
import AppDrawer.Model
import Context
import Entity exposing (inboxEntity)
import Entity.Types exposing (GroupEntityType(ContextEntity), createContextEntity)
import ExclusiveMode
import Firebase
import Firebase.Main
import Firebase.SignIn
import Keyboard.Combo exposing (combo2)
import LocalPref
import Material
import Model
import Project
import Random.Pcg
import Return
import RouteUrl
import Routes
import Set
import Store
import Time
import Todo.Main
import Todo.Notification.Model
import Todo.Store
import Todo.TimeTracker
import Update
import View
import X.Keyboard
import Json.Encode as E
import Msg exposing (Msg)
import Types exposing (AppModel, Flags, LocalPref, Return, defaultView)
import X.Random
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import ViewType exposing (ViewType(EntityListView))
import Toolkit.Operators exposing (..)


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)


main : RouteUrl.RouteUrlProgram Flags AppModel Msg.Msg
main =
    RouteUrl.programWithFlags
        { delta2url = Routes.delta2hash
        , location2messages = Routes.hash2messages
        , init = init
        , update = update
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


init : Flags -> Return
init flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        storeGenerator =
            Random.Pcg.map3 (,,)
                (Todo.Store.generator flags.deviceId encodedTodoList)
                (Project.storeGenerator flags.deviceId encodedProjectList)
                (Context.storeGenerator flags.deviceId encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)

        firebaseModel =
            Firebase.init flags.deviceId

        localPref =
            LocalPref.decode flags.localPref

        model : AppModel
        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = ExclusiveMode.none
            , mainViewType = defaultView
            , keyboardState = X.Keyboard.init
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , user = firebaseModel.user
            , fcmToken = firebaseModel.fcmToken
            , firebaseClient = firebaseModel.firebaseClient
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity = createContextEntity Context.null
            , timeTracker = Todo.TimeTracker.none
            , keyComboModel =
                Keyboard.Combo.init
                    { toMsg = Msg.OnKeyCombo
                    , combos = keyboardCombos
                    }
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , signInModel = localPref.signIn
            , mdl = Material.model
            }
    in
        update Msg.onSwitchToNewUserSetupModeIfNeeded model


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ combo2 ( Keyboard.Combo.shift, Keyboard.Combo.s ) (Msg.onStopRunningTodo)
    , combo2 ( Keyboard.Combo.shift, Keyboard.Combo.r ) (Msg.onGotoRunningTodo)
    ]


update : Msg -> AppModel -> Return
update msg =
    let
        andThenUpdate =
            update >> Return.andThen
    in
        Return.singleton
            >> Update.update andThenUpdate msg
