module Model exposing (..)

import AppDrawer.Model
import CommonMsg
import Context
import Document exposing (Document)
import Document.Types exposing (DocId)
import Entity.Types exposing (EntityListViewType, EntityType)
import Entity exposing (inboxEntity)
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Firebase
import Firebase.SignIn
import Material
import Model.ExMode exposing (createSetupExclusiveMode, deactivateEditingMode, setEditMode, startEditingEntity)
import Msg exposing (..)
import Stores exposing (setContextStore, setProjectStore, updateContext, updateProject, updateTodo)
import Todo.Types exposing (TodoAction(..), TodoDoc, TodoStore)
import Types exposing (AppConfig, AppModel, ModelF, ModelReturnF)
import ViewType exposing (ViewType(EntityListView))
import X.Keyboard as Keyboard exposing (KeyboardEvent, KeyboardState)
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Keyboard.Combo exposing (combo1, combo2, combo3)
import Keyboard.Combo as Combo
import Project
import Todo.Notification.Model
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import X.Random as Random
import X.Function.Infix exposing (..)
import Random.Pcg as Random exposing (Seed)
import Return
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo
import Todo.Msg
import Todo.Store
import Toolkit.Operators exposing (..)
import Tuple2
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Todo.TimeTracker
import X.Debug


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ combo2 ( Combo.shift, Combo.s ) (onTodoStopRunning)
    , combo2 ( Combo.shift, Combo.r ) (onGotoRunningTodo)
    ]


onTodoStopRunning =
    Todo.Msg.StopRunning |> OnTodoMsg


onGotoRunningTodo =
    Todo.Msg.GotoRunning |> OnTodoMsg


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


logString =
    commonMsg.logString


type alias Subscriptions =
    AppModel -> Sub Msg


type alias LocalPref =
    { appDrawer : AppDrawer.Model.Model
    , signIn : Firebase.SignIn.Model
    }


localPrefDecoder =
    D.succeed LocalPref
        |> D.optional "appDrawer" AppDrawer.Model.decoder AppDrawer.Model.default
        |> D.optional "signIn" Firebase.SignIn.decoder Firebase.SignIn.default


encodeLocalPref model =
    E.object
        [ "appDrawer" => AppDrawer.Model.encoder model.appDrawerModel
        , "signIn" => Firebase.SignIn.encode model.signInModel
        ]


defaultLocalPref : LocalPref
defaultLocalPref =
    { appDrawer = AppDrawer.Model.default
    , signIn = Firebase.SignIn.default
    }


type alias Flags =
    { now : Time
    , encodedTodoList : List Todo.Encoded
    , encodedProjectList : List E.Value
    , encodedContextList : List E.Value
    , pouchDBRemoteSyncURI : String
    , developmentMode : Bool
    , appVersion : String
    , deviceId : String
    , config : AppConfig
    , localPref : D.Value
    }



-- Model Lens


appDrawerModel =
    X.Record.field .appDrawerModel (\s b -> { b | appDrawerModel = s })


signInModel =
    X.Record.field .signInModel (\s b -> { b | signInModel = s })


overAppDrawerModel =
    over appDrawerModel


mapOverAppDrawerModel =
    over appDrawerModel >> Return.map


keyboardState =
    X.Record.field .keyboardState (\s b -> { b | keyboardState = s })


now =
    X.Record.field .now (\s b -> { b | now = s })


focusInEntity =
    X.Record.field .focusInEntity (\s b -> { b | focusInEntity = s })


keyComboModel =
    X.Record.field .keyComboModel (\s b -> { b | keyComboModel = s })


init : Flags -> Return.Return Msg AppModel
init flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        storeGenerator =
            Random.map3 (,,)
                (Todo.Store.generator flags.deviceId encodedTodoList)
                (Project.storeGenerator flags.deviceId encodedProjectList)
                (Context.storeGenerator flags.deviceId encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.step storeGenerator (Random.seedFromTime now)

        firebaseModel =
            Firebase.init flags.deviceId

        localPref =
            D.decodeValue localPrefDecoder flags.localPref
                |> Result.mapError (X.Debug.log "Unable to decode localPref")
                != defaultLocalPref

        editMode =
            if Firebase.SignIn.shouldSkipSignIn localPref.signIn then
                if Store.isEmpty todoStore then
                    createSetupExclusiveMode
                else
                    ExclusiveMode.none
            else
                ExclusiveMode.signInOverlay

        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = editMode
            , mainViewType = defaultView
            , keyboardState = Keyboard.init
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , user = firebaseModel.user
            , fcmToken = firebaseModel.fcmToken
            , firebaseClient = firebaseModel.firebaseClient
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity = inboxEntity
            , timeTracker = Todo.TimeTracker.none
            , keyComboModel =
                Keyboard.Combo.init
                    { toMsg = OnKeyCombo
                    , combos = keyboardCombos
                    }
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , signInModel = localPref.signIn
            , mdl = Material.model
            }
    in
        model |> Return.singleton


defaultView =
    EntityListView Entity.defaultListView


removeReminderOverlay model =
    { model | reminderOverlay = Todo.Notification.Model.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = Todo.Notification.Model.snoozeView details }


snoozeTodoWithOffset snoozeOffset todoId model =
    let
        time =
            Todo.Notification.Model.addSnoozeOffset model.now snoozeOffset
    in
        model
            |> updateTodo (time |> TA_SnoozeTill) todoId
            >> Tuple.mapFirst removeReminderOverlay


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (setProjectStore # model)
        |> (\( project, model ) ->
                model
                    |> switchToProjectView project
                    |> startEditingEntity (Entity.fromProject project)
           )


createAndEditNewContext model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (setContextStore # model)
        |> (\( context, model ) ->
                model
                    |> switchToContextView context
                    |> startEditingEntity (Entity.fromContext context)
           )


switchToNewUserSetupModeIfNeeded model =
    if Store.isEmpty model.todoStore then
        setEditMode createSetupExclusiveMode model
    else
        deactivateEditingMode model


switchToEntityListViewFromEntity entity model =
    let
        maybeEntityListViewType =
            maybeGetCurrentEntityListViewType model
    in
        entity
            |> Entity.toViewType maybeEntityListViewType
            |> (setEntityListViewType # model)


toggleDeleteEntity : EntityType -> ModelReturnF
toggleDeleteEntity entity model =
    let
        entityId =
            Entity.getId entity
    in
        model
            |> case entity of
                Entity.Types.GroupEntity g ->
                    case g of
                        Entity.Types.ContextEntity context ->
                            updateContext entityId Document.toggleDeleted

                        Entity.Types.ProjectEntity project ->
                            updateProject entityId Document.toggleDeleted

                Entity.Types.TodoEntity todo ->
                    updateTodo (TA_ToggleDeleted) entityId


getMaybeEditTodoReminderForm model =
    case model.editMode of
        XMEditTodoReminder form ->
            Just form

        _ ->
            Nothing


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                XMEditSyncSettings form ->
                    Just form

                _ ->
                    Nothing
    in
        maybeForm ?= createRemoteSyncForm model


createRemoteSyncForm : AppModel -> SyncForm
createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }


getEditMode : AppModel -> ExclusiveMode
getEditMode =
    (.editMode)


clearSelection =
    setSelectedEntityIdSet Set.empty


getMainViewType : AppModel -> ViewType
getMainViewType =
    (.mainViewType)


switchToView : ViewType -> ModelF
switchToView mainViewType model =
    { model | mainViewType = mainViewType }
        |> clearSelection


projectView =
    Document.getId >> Entity.Types.ProjectView >> EntityListView


contextView =
    Document.getId >> Entity.Types.ContextView >> EntityListView


switchToProjectView =
    projectView >> switchToView


switchToContextView =
    contextView >> switchToView


switchToContextsView =
    EntityListView Entity.Types.ContextsView |> switchToView


setEntityListViewType =
    EntityListView >> switchToView


maybeGetCurrentEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


toggleEntitySelection entity =
    updateSelectedEntityIdSet (toggleSetMember (Entity.getId entity))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


getSelectedEntityIdSet : AppModel -> Set DocId
getSelectedEntityIdSet =
    (.selectedEntityIdSet)


setSelectedEntityIdSet : Set DocId -> ModelF
setSelectedEntityIdSet selectedEntityIdSet model =
    { model | selectedEntityIdSet = selectedEntityIdSet }


updateSelectedEntityIdSet : (Set DocId -> Set DocId) -> ModelF
updateSelectedEntityIdSet updater model =
    setSelectedEntityIdSet (updater (getSelectedEntityIdSet model)) model


getNow : AppModel -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


getKeyboardState : AppModel -> KeyboardState
getKeyboardState =
    (.keyboardState)


setKeyboardState : KeyboardState -> ModelF
setKeyboardState keyboardState model =
    { model | keyboardState = keyboardState }


updateKeyboardState : (KeyboardState -> KeyboardState) -> ModelF
updateKeyboardState updater model =
    setKeyboardState (updater (getKeyboardState model)) model



-- Focus Functions


getMaybeFocusInEntity entityList model =
    entityList
        |> List.find (Entity.equalById model.focusInEntity)
        |> Maybe.orElse (List.head entityList)


moveFocusBy : Int -> List EntityType -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity


updateCombo : Keyboard.Combo.Msg -> ModelReturnF
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")
