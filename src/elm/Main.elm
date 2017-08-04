module Main exposing (main)

import AppDrawer.GroupViewModel exposing (DocumentWithNameViewModel)
import AppDrawer.Model
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Data.TodoDoc exposing (..)
import Document exposing (..)
import Entity exposing (..)
import ExclusiveMode.Types exposing (..)
import Firebase exposing (..)
import Firebase.Model exposing (..)
import GroupDoc exposing (..)
import Html exposing (Html, text)
import Json.Encode as E
import Keyboard
import Keyboard.Extra as KX exposing (Key)
import Mat exposing (cs)
import Material
import Material.Options exposing (div)
import Menu
import Menu.Types
import Models.Selection
import Models.Todo
import Navigation
import Pages.EntityList exposing (HasEntityListCursor)
import Ports
import Ports.Firebase exposing (..)
import Ports.Todo exposing (..)
import Random.Pcg
import RouteUrl
import RouteUrl.Builder
import Set exposing (Set)
import Time exposing (Time)
import Todo.FormTypes
import Todo.Notification.Model
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Toolkit.Operators exposing (..)
import Update.AppDrawer
import Update.AppHeader exposing (AppHeaderMsg(..))
import Update.ExclusiveMode exposing (ExclusiveModeMsg)
import Update.Firebase exposing (..)
import Update.GroupDoc exposing (..)
import Update.Subscription
import Update.Todo exposing (TodoMsg)
import View.Layout
import View.NewTodoFab exposing (newTodoFab)
import View.Overlays
import ViewModel.EntityList
import Views.EntityList
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)


type Page
    = EntityListPage Pages.EntityList.PageModel


initialPage =
    EntityListPage Pages.EntityList.defaultPageModel


type alias AppConfig =
    { deviceId : String
    , npmPackageVersion : String
    , isDevelopmentMode : Bool
    , debug : Bool
    , initialOfflineStore : E.Value
    }


type alias AppModel =
    HasEntityListCursor AppModelOtherFields


type alias AppModelOtherFields =
    { lastKnownCurrentTime : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , page : Page
    , reminderOverlay : TodoReminderOverlayModel
    , pouchDBRemoteSyncURI : String
    , firebaseModel : FirebaseModel
    , developmentMode : Bool
    , selectedEntityIdSet : Set DocId
    , appVersion : String
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.AppDrawerModel
    , mdl : Material.Model
    }


type SubscriptionMsg
    = OnPouchDBChange String E.Value
    | OnFirebaseDatabaseChange String E.Value


type AppMsg
    = NOOP
    | OnSubscriptionMsg SubscriptionMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | EntityListMsg Pages.EntityList.Msg
    | OnGroupDocMsg GroupDocMsg
    | OnGroupDocMsgWithNow GroupDocMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnAppDrawerMsg AppDrawer.Types.AppDrawerMsg
    | OnMdl (Material.Msg AppMsg)
    | OnGlobalKeyUp Int
    | OnGlobalKeyDown Int
    | SetLastKnownTimeStamp Time
    | PageMsg_NavigateToPath (List String)


navigateToPathMsg =
    PageMsg_NavigateToPath


onStartAddingTodoWithFocusInEntityAsReferenceOld : AppModel -> AppMsg
onStartAddingTodoWithFocusInEntityAsReferenceOld model =
    Pages.EntityList.getMaybeEntityIdAtCursor__ model
        |> Update.Todo.onStartAddingTodoWithFocusInEntityAsReference
        |> OnTodoMsg


revertExclusiveModeMsg =
    Update.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus
        |> OnExclusiveModeMsg


onSaveExclusiveModeForm : AppMsg
onSaveExclusiveModeForm =
    Update.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg


setFocusInEntityWithEntityIdMsg : EntityId -> AppMsg
setFocusInEntityWithEntityIdMsg =
    Pages.EntityList.SetFocusableEntityId >> EntityListMsg


subscriptions : AppModel -> Sub AppMsg
subscriptions model =
    let
        everyXSeconds x =
            Time.every (Time.second * x * debugSecondMultiplier)

        debugSecondMultiplier =
            if model.config.debug then
                60
            else
                1
    in
    Sub.batch
        [ Keyboard.ups OnGlobalKeyUp
        , Keyboard.downs OnGlobalKeyDown
        , everyXSeconds 1 SetLastKnownTimeStamp
        , Sub.batch
            [ Ports.pouchDBChanges (uncurry OnPouchDBChange)
            , Ports.onFirebaseDatabaseChange (uncurry OnFirebaseDatabaseChange)
            ]
            |> Sub.map OnSubscriptionMsg
        , Sub.batch
            [ notificationClicked Update.Todo.OnReminderNotificationClicked

            -- note: 30 seconds is so that we can received any updates from firebase
            -- before triggering and changing any stale overdue todos timestamps.
            , everyXSeconds 30 (\_ -> Update.Todo.OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map OnTodoMsg
        , Sub.batch
            [ onFirebaseUserChanged OnFBUserChanged
            , onFCMTokenChanged OnFBFCMTokenChanged
            , onFirebaseConnectionChanged OnFBConnectionChanged
            ]
            |> Sub.map OnFirebaseMsg
        , Update.AppDrawer.subscriptions
            |> Sub.map OnAppDrawerMsg
        ]


type alias Flags =
    { now : Time
    , encodedTodoList : List E.Value
    , encodedProjectList : List E.Value
    , encodedContextList : List E.Value
    , pouchDBRemoteSyncURI : String
    , config : AppConfig
    }


createAppModel : Flags -> AppModel
createAppModel flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        { deviceId, initialOfflineStore, npmPackageVersion, isDevelopmentMode } =
            flags.config

        storeGenerator =
            Random.Pcg.map3 (,,)
                (Data.TodoDoc.storeGenerator deviceId encodedTodoList)
                (GroupDoc.projectStoreGenerator deviceId encodedProjectList)
                (GroupDoc.contextStoreGenerator deviceId encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.Pcg.step storeGenerator (X.Random.seedFromTime now)

        model : AppModel
        model =
            { lastKnownCurrentTime = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , page = initialPage
            , reminderOverlay = Todo.Notification.Model.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , firebaseModel =
                Firebase.init deviceId initialOfflineStore
            , developmentMode = isDevelopmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = npmPackageVersion
            , config = flags.config
            , appDrawerModel = AppDrawer.Model.initialValue initialOfflineStore
            , mdl = Material.model
            , entityListCursor = Pages.EntityList.entityListCursorInitialValue
            }
    in
    model


type alias UpdateConfig msg =
    Update.AppHeader.Config msg
        (Update.ExclusiveMode.Config msg
            (Update.Firebase.Config msg
                (Update.Subscription.Config msg
                    (Update.Todo.Config msg
                        { navigateToPathMsg : List String -> msg
                        }
                    )
                )
            )
        )


updateConfig : AppModel -> UpdateConfig AppMsg
updateConfig model =
    { onStartAddingTodoToInbox = Update.Todo.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onSetExclusiveMode = Update.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveMode = revertExclusiveModeMsg
    , onStartSetupAddTodo = Update.Todo.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Update.Todo.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocForm = OnSaveGroupDocForm >> OnGroupDocMsg
    , focusNextEntityMsgNew = EntityListMsg Pages.EntityList.ArrowDown
    , focusPrevEntityMsgNew = EntityListMsg Pages.EntityList.ArrowUp
    , navigateToPathMsg = navigateToPathMsg
    , isTodoStoreEmpty = Models.Todo.isStoreEmpty model
    }


update : UpdateConfig AppMsg -> AppMsg -> ReturnF AppMsg AppModel
update config msg =
    case msg of
        NOOP ->
            identity

        PageMsg_NavigateToPath path ->
            let
                setPage page =
                    map (\model -> { model | page = page })
                        >> map Models.Selection.clearSelection
                        >> returnMsgAsCmd config.revertExclusiveMode

                setMaybePage page =
                    page ?|> setPage ?= effect revertHref

                revertHref model =
                    case model.page of
                        EntityListPage pageModel ->
                            Pages.EntityList.getFullPath pageModel
                                |> String.join "/"
                                |> (++) "#!/"
                                |> Navigation.modifyUrl
            in
            case path of
                _ ->
                    Pages.EntityList.initFromPath path
                        ?|> EntityListPage
                        |> setMaybePage

        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        OnGlobalKeyUp keyCode ->
            Update.Subscription.onGlobalKeyUp config (KX.fromCode keyCode)

        OnGlobalKeyDown keyCode ->
            Update.Subscription.onGlobalKeyDown config (KX.fromCode keyCode)

        SetLastKnownTimeStamp now ->
            map (\model -> { model | lastKnownCurrentTime = now })

        OnSubscriptionMsg msg_ ->
            onSubscriptionMsg config msg_

        OnGroupDocMsg msg_ ->
            returnWithNow (OnGroupDocMsgWithNow msg_)

        OnGroupDocMsgWithNow msg_ now ->
            Update.GroupDoc.update config now msg_

        OnExclusiveModeMsg msg_ ->
            Update.ExclusiveMode.update config msg_

        OnAppHeaderMsg msg_ ->
            Update.AppHeader.update config msg_

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_

        OnFirebaseMsg msg_ ->
            let
                firebaseModel =
                    fieldLens .firebaseModel (\s b -> { b | firebaseModel = s })
            in
            overReturnF firebaseModel (Update.Firebase.update config msg_)

        OnAppDrawerMsg msg_ ->
            let
                appDrawerModel =
                    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })
            in
            overReturnFMapCmd appDrawerModel OnAppDrawerMsg (Update.AppDrawer.update msg_)

        _ ->
            returnWith identity (getPage__ >> updatePage config msg)


updatePage config msg page =
    case ( page, msg ) of
        ( EntityListPage model_, EntityListMsg msg_ ) ->
            Pages.EntityList.update config msg_ model_

        _ ->
            identity


onSubscriptionMsg config msg =
    case msg of
        OnPouchDBChange dbName encodedDoc ->
            Update.Subscription.onPouchDBChange config dbName encodedDoc

        OnFirebaseDatabaseChange dbName encodedDoc ->
            effect (Update.Subscription.upsertEncodedDocOnFirebaseDatabaseChange dbName encodedDoc)


type alias ViewConfig msg =
    { noop : msg
    , onAppDrawerMsg : AppDrawer.Types.AppDrawerMsg -> msg
    , onFirebaseMsg : FirebaseMsg -> msg
    , onMainMenuStateChanged : Menu.Types.MenuState -> msg
    , onMdl : Material.Msg msg -> msg
    , onReminderOverlayAction : Todo.Notification.Model.Action -> msg
    , onSaveExclusiveModeForm : msg
    , onSetContext : DocId -> ContextDoc -> msg
    , onSetProject : DocId -> ProjectDoc -> msg
    , onSetTodoFormMenuState : Todo.FormTypes.TodoForm -> Menu.State -> msg
    , onSetTodoFormReminderDate : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormReminderTime : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormText : Todo.FormTypes.TodoForm -> String -> msg
    , onShowMainMenu : msg
    , onSignIn : msg
    , onSignOut : msg
    , onStartAddingGroupDoc : GroupDocType -> msg
    , onStartAddingTodoWithFocusInEntityAsReference : msg
    , onStartEditingGroupDoc : GroupDocId -> msg
    , onStartEditingReminder : TodoDoc -> msg
    , onStartEditingTodoContext : TodoDoc -> msg
    , onStartEditingTodoProject : TodoDoc -> msg
    , onStartEditingTodoText : TodoDoc -> msg
    , onToggleAppDrawerOverlay : msg
    , onToggleDeleted : DocId -> msg
    , onToggleDeletedAndMaybeSelection : DocId -> msg
    , onToggleDoneAndMaybeSelection : DocId -> msg
    , onToggleEntitySelection : Entity.EntityId -> msg
    , onToggleGroupDocArchived : GroupDocId -> msg
    , revertExclusiveMode : msg
    , setFocusInEntityWithEntityId : Entity.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDocForm -> GroupDocName -> msg
    , maybeEntityIdAtCursorOld : Maybe EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    , navigateToPathMsg : List String -> msg
    }


viewConfig : AppModel -> ViewConfig AppMsg
viewConfig model =
    { onSetProject = Update.Todo.onSetProjectAndMaybeSelectionMsg >>> OnTodoMsg
    , onSetContext = Update.Todo.onSetContextAndMaybeSelectionMsg >>> OnTodoMsg
    , onSetTodoFormMenuState = Update.Todo.onSetTodoFormMenuStateMsg >>> OnTodoMsg
    , noop = NOOP
    , revertExclusiveMode = revertExclusiveModeMsg
    , onSetTodoFormText = Update.Todo.onSetTodoFormTextMsg >>> OnTodoMsg
    , onToggleDeleted = Update.Todo.onToggleDeletedMsg >> OnTodoMsg
    , onSetTodoFormReminderDate = Update.Todo.onSetTodoFormReminderDateMsg >>> OnTodoMsg
    , onSetTodoFormReminderTime = Update.Todo.onSetTodoFormReminderTimeMsg >>> OnTodoMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onMainMenuStateChanged = OnMainMenuStateChanged >> OnAppHeaderMsg
    , onSignIn = OnFirebaseMsg OnFBSignIn
    , onSignOut = OnFirebaseMsg OnFBSignOut
    , onFirebaseMsg = OnFirebaseMsg
    , onReminderOverlayAction = Update.Todo.onReminderOverlayActionMsg >> OnTodoMsg
    , onToggleAppDrawerOverlay = OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay
    , onAppDrawerMsg = OnAppDrawerMsg
    , onStartAddingGroupDoc = OnGroupDocAction # GDA_StartAdding >> OnGroupDocMsg
    , onMdl = OnMdl
    , onShowMainMenu = OnShowMainMenu |> OnAppHeaderMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onToggleEntitySelection = Pages.EntityList.ToggleSelection >> EntityListMsg
    , onStartEditingTodoProject = Update.Todo.onStartEditingTodoProjectMsg >> OnTodoMsg
    , onStartEditingTodoContext = Update.Todo.onStartEditingTodoContextMsg >> OnTodoMsg
    , onStartEditingTodoText = Update.Todo.onStartEditingTodoTextMsg >> OnTodoMsg
    , onStartEditingReminder = Update.Todo.onStartEditingReminderMsg >> OnTodoMsg
    , onToggleDeletedAndMaybeSelection = Update.Todo.onToggleDeletedAndMaybeSelectionMsg >> OnTodoMsg
    , onToggleDoneAndMaybeSelection = Update.Todo.onToggleDoneAndMaybeSelectionMsg >> OnTodoMsg
    , onToggleGroupDocArchived = toggleGroupDocArchivedMsg >> OnGroupDocMsg
    , updateGroupDocFromNameMsg =
        updateGroupDocFromNameMsg >>> OnGroupDocMsg
    , onStartEditingGroupDoc = startEditingGroupDocMsg >> OnGroupDocMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , maybeEntityIdAtCursorOld = Nothing
    , maybeEntityIdAtCursor = Nothing
    , navigateToPathMsg = navigateToPathMsg
    }


view : ViewConfig msg -> AppModel -> Html msg
view config model =
    let
        frameVM =
            let
                ( mainHeaderTitle, headerBackgroundColor ) =
                    case getPage__ model of
                        EntityListPage pageModel ->
                            Pages.EntityList.getTitleColourTuple pageModel
            in
            { contexts = AppDrawer.GroupViewModel.contexts config model
            , projects = AppDrawer.GroupViewModel.projects config model
            , mainHeaderTitle = mainHeaderTitle
            , headerBackgroundColor = headerBackgroundColor
            , mdl = model.mdl
            }

        frame pageContent =
            div [ cs "mdl-typography--body-1" ]
                ([ View.Layout.appLayoutView config frameVM model pageContent
                 , newTodoFab config model
                 ]
                    ++ View.Overlays.overlayViews config model
                )
    in
    case getPage__ model of
        EntityListPage pageModel ->
            let
                pageVM =
                    ViewModel.EntityList.pageVM config pageModel model
            in
            Views.EntityList.view pageVM |> frame


getPage__ =
    .page


delta2hash =
    let
        getPathFromModel model =
            case getPage__ model of
                EntityListPage pageModel ->
                    Pages.EntityList.getFullPath pageModel

        delta2builder previousModel currentModel =
            RouteUrl.Builder.builder
                |> RouteUrl.Builder.replacePath (getPathFromModel currentModel)
    in
    delta2builder >>> RouteUrl.Builder.toHashChange >> Just


hash2messages config location =
    let
        builder =
            RouteUrl.Builder.fromHash location.href

        path =
            RouteUrl.Builder.path builder
    in
    [ config.navigateToPathMsg path ]


main : RouteUrl.RouteUrlProgram Flags AppModel AppMsg
main =
    let
        init =
            createAppModel
                >> update_ (OnFirebaseMsg OnFB_SwitchToNewUserSetupModeIfNeeded)

        update_ : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
        update_ msg model =
            model |> pure >> update (updateConfig model) msg
    in
    RouteUrl.programWithFlags
        { delta2url = delta2hash
        , location2messages =
            hash2messages
                { navigateToPathMsg = navigateToPathMsg
                }
        , init = init
        , update = update_
        , view = \model -> view (viewConfig model) model
        , subscriptions = subscriptions
        }
