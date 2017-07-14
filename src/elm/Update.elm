port module Update exposing (update)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, autoFocusInputRCmd, focusSelectorIfNoFocusRCmd)
import Entity
import Entity.Main
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Types exposing (..)
import Firebase.Main
import LocalPref
import Main.Update
import Material
import Menu
import Model.Internal exposing (deactivateEditingMode, setExclusiveMode)
import Model.Keyboard
import Model.ViewType
import Msg exposing (..)
import Stores
import Todo.Form
import Todo.FormTypes exposing (..)
import Update.ExMode
import Update.LaunchBar
import Update.Subscription
import X.Return as Return
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Form
import Return
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import Types exposing (AppModel, ModelF, Return, ReturnF)
import X.Record exposing (maybeOver)


foo =
    2


map =
    Return.map


update :
    (AppMsg -> ReturnF)
    -> AppMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubMsg subMsg ->
            Update.Subscription.onSubMsg andThenUpdate subMsg

        OnMainMsg mainMsg ->
            Main.Update.update andThenUpdate mainMsg

        OnShowMainMenu ->
            map (setExclusiveMode (Menu.initState |> XMMainMenu))
                >> Return.command positionMainMenuCmd

        OnEntityListKeyDown entityList { key, isShiftDown } ->
            case key of
                Key.ArrowUp ->
                    map (moveFocusBy -1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                Key.ArrowDown ->
                    map (moveFocusBy 1 entityList)
                        >> andThenUpdate setDomFocusToFocusInEntityCmd

                _ ->
                    identity

        OnRemotePouchSync form ->
            andThenUpdate OnSaveExclusiveModeForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnDeactivateEditingMode ->
            map (deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        OnStartAddingTodo atfMode ->
            -- todo: think about merging 4 messages into one.
            let
                createXM model =
                    Todo.Form.createAddTodoForm atfMode |> XMTodoForm
            in
                Return.mapModelWith createXM setExclusiveMode
                    >> command autoFocusInputCmd

        OnUpdateAddTodoForm form text ->
            let
                xm =
                    form
                        |> Todo.Form.updateEditTodoForm (SetTodoText text)
                        >> XMTodoForm
            in
                map (setExclusiveMode xm)

        OnStartEditingTodo todo t ->
            let
                createXM model =
                    Todo.Form.createEditTodoForm t model.now todo |> XMTodoForm
            in
                Return.mapModelWith createXM setExclusiveMode
                    >> command
                        (case t of
                            ETFM_EditTodoText ->
                                autoFocusInputCmd

                            ETFM_EditTodoContext ->
                                positionContextMenuCmd todo

                            ETFM_EditTodoProject ->
                                positionProjectMenuCmd todo

                            ETFM_EditTodoReminder ->
                                positionScheduleMenuCmd todo
                        )

        OnUpdateEditTodoForm form action ->
            let
                xm =
                    Todo.Form.updateEditTodoForm action form |> XMTodoForm
            in
                map (setExclusiveMode xm)
                    >> Return.command
                        (case action of
                            Todo.FormTypes.SetTodoMenuState _ ->
                                autoFocusInputCmd

                            _ ->
                                Cmd.none
                        )

        OnMainMenuStateChanged menuState ->
            map
                (menuState
                    |> XMMainMenu
                    >> setExclusiveMode
                )
                >> autoFocusInputRCmd

        OnUpdateRemoteSyncFormUri form uri ->
            map
                ({ form | uri = uri }
                    |> XMEditSyncSettings
                    >> setExclusiveMode
                )

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

        OnSaveExclusiveModeForm ->
            Update.ExMode.onSaveExclusiveModeForm andThenUpdate

        OnEntityMsg entityMsg ->
            Entity.Main.update andThenUpdate entityMsg

        LaunchBarMsgWithNow msg now ->
            Update.LaunchBar.update andThenUpdate msg now

        LaunchBarMsg msg ->
            withNow (LaunchBarMsgWithNow msg)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnKeyCombo comboMsg ->
            Return.andThen (Model.Keyboard.updateCombo comboMsg)

        OnTodoMsg todoMsg ->
            withNow (OnTodoMsgWithTime todoMsg)

        OnTodoMsgWithTime todoMsg now ->
            Todo.Main.update andThenUpdate now todoMsg

        OnFirebaseMsg firebaseMsg ->
            Firebase.Main.update andThenUpdate firebaseMsg

        OnAppDrawerMsg msg ->
            AppDrawer.Main.update andThenUpdate msg

        OnPersistLocalPref ->
            Return.effect_ (LocalPref.encodeLocalPref >> persistLocalPref)

        OnMdl msg_ ->
            Return.andThen (Material.update OnMdl msg_)


moveFocusBy : Int -> List Entity -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity


withNow : (Time -> AppMsg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


command =
    Return.command


positionContextMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-context-button-" ++ Document.getId todo)


positionMainMenuCmd =
    DomPorts.positionPopupMenu "#main-menu-button"


positionProjectMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-project-button-" ++ Document.getId todo)


positionScheduleMenuCmd todo =
    DomPorts.positionPopupMenu ("#edit-schedule-button-" ++ Document.getId todo)


port syncWithRemotePouch : String -> Cmd msg


port persistLocalPref : D.Value -> Cmd msg
