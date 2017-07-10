port module Update exposing (..)

import AppDrawer.Main
import CommonMsg
import Document
import DomPorts exposing (autoFocusInputCmd, focusSelectorIfNoFocusCmd)
import Entity
import Entity.Main
import Entity.Types exposing (Entity(TodoEntity))
import ExclusiveMode.Main
import ExclusiveMode.Types exposing (ExclusiveMode(..))
import Firebase.Main
import LaunchBar.Types exposing (LBMsg(OnLBOpen))
import LocalPref
import Main.Update
import Material
import Model.ExMode
import Model.Msg
import Model.Selection
import Model.ViewType
import Msg exposing (..)
import Stores
import X.Keyboard as Keyboard exposing (Key)
import X.Return as Return
import X.Function.Infix exposing (..)
import Keyboard.Extra as Key
import Notification
import Todo.Form
import Todo.GroupForm
import Todo.Msg
import Return
import Task
import Time exposing (Time)
import Model exposing (..)
import Todo.Main
import Json.Decode as D exposing (Decoder)
import LaunchBar.Main
import Tuple2
import Types exposing (AppModel, ModelF, Return, ReturnF)
import Toolkit.Helpers exposing (..)
import X.Record exposing (maybeOver)


map =
    Return.map


update :
    (Msg -> ReturnF)
    -> Msg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        OnCommonMsg msg ->
            CommonMsg.update msg

        OnSubMsg subMsg ->
            onSubMsg andThenUpdate subMsg

        OnStartExclusiveMode exclusiveMode ->
            ExclusiveMode.Main.start exclusiveMode

        OnMainMsg mainMsg ->
            Main.Update.update andThenUpdate mainMsg

        OnShowMainMenu ->
            map Model.ExMode.showMainMenu
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
            andThenUpdate OnSaveCurrentForm
                >> Return.effect_ (.pouchDBRemoteSyncURI >> syncWithRemotePouch)

        OnDeactivateEditingMode ->
            map (Model.ExMode.deactivateEditingMode)
                >> andThenUpdate setDomFocusToFocusInEntityCmd

        OnStartEditingContext todo ->
            map (Model.ExMode.startEditingTodoContext todo)
                >> Return.command (positionContextMenuCmd todo)

        OnStartEditingProject todo ->
            map (Model.ExMode.startEditingTodoProject todo)
                >> Return.command (positionProjectMenuCmd todo)

        OnNewTodoTextChanged form text ->
            map (Model.ExMode.updateNewTodoText form text)

        OnStartEditingReminder todo ->
            map (Model.ExMode.startEditingReminder todo)
                >> Return.command (positionScheduleMenuCmd todo)

        OnUpdateTodoForm form action ->
            map
                (Todo.Form.set action form
                    |> XMEditTodo
                    >> Model.ExMode.setEditMode
                )

        OnEditTodoProjectMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> XMEditTodoProject
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnMainMenuStateChanged menuState ->
            map
                (menuState
                    |> XMMainMenu
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnEditTodoContextMenuStateChanged form menuState ->
            map
                (Todo.GroupForm.setMenuState menuState form
                    |> XMEditTodoContext
                    >> Model.ExMode.setEditMode
                )
                >> autoFocusInputCmd

        OnUpdateRemoteSyncFormUri form uri ->
            map
                ({ form | uri = uri }
                    |> XMEditSyncSettings
                    >> Model.ExMode.setEditMode
                )

        OnSetViewType viewType ->
            map (Model.ViewType.switchToView viewType)

        OnSaveCurrentForm ->
            Return.andThen Model.ExMode.saveCurrentForm
                >> andThenUpdate OnDeactivateEditingMode

        OnEntityMsg entityMsg ->
            Entity.Main.update andThenUpdate entityMsg

        OnLaunchBarMsgWithNow msg now ->
            LaunchBar.Main.update andThenUpdate now msg

        OnLaunchBarMsg msg ->
            withNow (OnLaunchBarMsgWithNow msg)

        OnCloseNotification tag ->
            command (Notification.closeNotification tag)

        OnKeyCombo comboMsg ->
            Return.andThen (Model.updateCombo comboMsg)

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


withNow : (Time -> Msg) -> ReturnF
withNow toMsg =
    command (Task.perform toMsg Time.now)


updateTodoAndMaybeAlsoSelected action todoId =
    Return.andThen (Stores.updateTodoAndMaybeAlsoSelected action todoId)


maybeMapToCmd fn =
    Maybe.map fn >>?= Cmd.none


command =
    Return.command


onSubMsg andThenUpdate subMsg =
    case subMsg of
        OnNowChanged now ->
            map (Model.setNow now)

        OnKeyboardMsg msg ->
            map (Model.updateKeyboardState (Keyboard.update msg))
                >> focusSelectorIfNoFocusCmd ".entity-list .focusable-list-item[tabindex=0]"

        OnGlobalKeyUp key ->
            onGlobalKeyUp andThenUpdate key

        OnPouchDBChange dbName encodedDoc ->
            let
                afterEntityUpsertOnPouchDBChange entity =
                    case entity of
                        TodoEntity model ->
                            Todo.Msg.Upsert model |> OnTodoMsg

                        _ ->
                            Model.noop
            in
                Return.andThenMaybe
                    (Stores.upsertEncodedDocOnPouchDBChange dbName encodedDoc
                        >>? (Tuple2.mapEach afterEntityUpsertOnPouchDBChange Return.singleton
                                >> uncurry andThenUpdate
                            )
                    )

        OnFirebaseDatabaseChange dbName encodedDoc ->
            Return.effect_ (Stores.upsertEncodedDocOnFirebaseChange dbName encodedDoc)


onGlobalKeyUp andThenUpdate key =
    Return.with (Model.getEditMode)
        (\editMode ->
            case ( key, editMode ) of
                ( key, XMNone ) ->
                    let
                        clear =
                            map (Model.Selection.clearSelection)
                                >> andThenUpdate OnDeactivateEditingMode
                    in
                        case key of
                            Key.Escape ->
                                clear

                            Key.CharX ->
                                clear

                            Key.CharQ ->
                                Return.andThen
                                    (apply2
                                        ( Model.Msg.onNewTodoModeWithFocusInEntityAsReference
                                        , Return.singleton
                                        )
                                        >> uncurry andThenUpdate
                                    )

                            {- (\model ->
                                   model
                                       |> Return.singleton
                                       >> andThenUpdate (Model.Msg.onNewTodoModeWithFocusInEntityAsReference model)
                               )
                            -}
                            Key.CharI ->
                                andThenUpdate Msg.onNewTodoForInbox

                            Key.Slash ->
                                OnLBOpen |> OnLaunchBarMsg |> andThenUpdate

                            _ ->
                                identity

                ( Key.Escape, _ ) ->
                    andThenUpdate OnDeactivateEditingMode

                _ ->
                    identity
        )


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
