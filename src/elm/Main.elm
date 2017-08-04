module Main exposing (main)

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
import Material
import Maybe.Extra
import Menu
import Menu.Types
import Models.Selection
import Models.Todo
import Navigation
import Pages.EntityList as EntityList
import Ports.Todo
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
import Update.Subscription exposing (SubscriptionMsg)
import Update.Todo exposing (TodoMsg)
import View.Frame
import ViewModel.EntityList
import ViewModel.Frame
import Views.EntityList
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)
import X.Set


type Page
    = EntityList EntityList.Model


initialPage =
    EntityList EntityList.initialValue


type alias AppConfig =
    { deviceId : String
    , npmPackageVersion : String
    , isDevelopmentMode : Bool
    , debug : Bool
    , initialOfflineStore : E.Value
    }


type alias Model =
    { lastKnownCurrentTime : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
    , contextStore : ContextStore
    , editMode : ExclusiveMode
    , page : Page
    , reminderOverlay : TodoReminderOverlayModel
    , firebaseModel : FirebaseModel
    , developmentMode : Bool
    , selectedEntityIdSet : Set DocId
    , appVersion : String
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.AppDrawerModel
    , mdl : Material.Model
    }


type Msg
    = NOOP
    | OnSubscriptionMsg SubscriptionMsg
    | OnExclusiveModeMsg ExclusiveModeMsg
    | OnAppHeaderMsg AppHeaderMsg
    | EntityListMsg EntityList.Msg
    | OnGroupDocMsg GroupDocMsg
    | OnGroupDocMsgWithNow GroupDocMsg Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithNow TodoMsg Time
    | OnFirebaseMsg FirebaseMsg
    | OnAppDrawerMsg AppDrawer.Types.AppDrawerMsg
    | OnMdl (Material.Msg Msg)
    | SetLastKnownTimeStamp Time
    | NavigateToPath (List String)
    | ToggleEntityIdSelection EntityId


navigateToPathMsg =
    NavigateToPath


onStartAddingTodoWithFocusInEntityAsReferenceOld : Model -> Msg
onStartAddingTodoWithFocusInEntityAsReferenceOld model =
    case model.page of
        EntityList pageModel ->
            EntityList.getMaybeLastKnownFocusedEntityId pageModel
                |> Update.Todo.onStartAddingTodoWithFocusInEntityAsReference
                |> OnTodoMsg


revertExclusiveModeMsg =
    Update.ExclusiveMode.OnSetExclusiveModeToNoneAndTryRevertingFocus
        |> OnExclusiveModeMsg


onSaveExclusiveModeForm : Msg
onSaveExclusiveModeForm =
    Update.ExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg


setFocusInEntityWithEntityIdMsg : EntityId -> Msg
setFocusInEntityWithEntityIdMsg =
    EntityList.SetCursorEntityId >> EntityListMsg


subscriptions : Model -> Sub Msg
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
        [ everyXSeconds 1 SetLastKnownTimeStamp
        , Update.Subscription.subscriptions
            |> Sub.map OnSubscriptionMsg
        , Sub.batch
            [ Ports.Todo.notificationClicked Update.Todo.OnReminderNotificationClicked

            -- note: 30 seconds is so that we can received any updates from firebase
            -- before triggering and changing any stale overdue todos timestamps.
            , everyXSeconds 30 (\_ -> Update.Todo.OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map OnTodoMsg
        , Update.Firebase.subscriptions |> Sub.map OnFirebaseMsg
        , Update.AppDrawer.subscriptions |> Sub.map OnAppDrawerMsg
        ]


type alias Flags =
    { now : Time
    , encodedTodoList : List E.Value
    , encodedProjectList : List E.Value
    , encodedContextList : List E.Value
    , config : AppConfig
    }


createAppModel : Flags -> Model
createAppModel flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList } =
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

        model : Model
        model =
            { lastKnownCurrentTime = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , page = initialPage
            , reminderOverlay = Todo.Notification.Model.none
            , firebaseModel =
                Firebase.init deviceId initialOfflineStore
            , developmentMode = isDevelopmentMode
            , selectedEntityIdSet = Set.empty
            , appVersion = npmPackageVersion
            , config = flags.config
            , appDrawerModel = AppDrawer.Model.initialValue initialOfflineStore
            , mdl = Material.model
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


createUpdateConfig : Model -> UpdateConfig Msg
createUpdateConfig model =
    { onStartAddingTodoToInbox = Update.Todo.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onSetExclusiveMode = Update.ExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveMode = revertExclusiveModeMsg
    , onStartSetupAddTodo = Update.Todo.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoForm = Update.Todo.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocForm = OnSaveGroupDocForm >> OnGroupDocMsg
    , focusNextEntityMsgNew = EntityList.MoveFocusBy 1 |> EntityListMsg
    , focusPrevEntityMsgNew = EntityList.MoveFocusBy -1 |> EntityListMsg
    , navigateToPathMsg = navigateToPathMsg
    , isTodoStoreEmpty = Models.Todo.isStoreEmpty model
    }


update : UpdateConfig Msg -> Msg -> ReturnF Msg Model
update config msg =
    case msg of
        NOOP ->
            identity

        ToggleEntityIdSelection entityId ->
            map
                (Models.Selection.updateSelectedEntityIdSet
                    (X.Set.toggleSetMember (getDocIdFromEntityId entityId))
                )

        NavigateToPath path ->
            let
                setPage page =
                    map (set pageFL page)
                        >> map Models.Selection.clearSelection
                        >> returnMsgAsCmd config.revertExclusiveMode

                revertPath path =
                    path
                        |> String.join "/"
                        |> (++) "#!/"
                        |> Navigation.modifyUrl
                        |> command
            in
            returnWith .page
                (\page ->
                    case page of
                        EntityList pageModel ->
                            EntityList.maybeInitFromPath path pageModel
                                |> Maybe.Extra.unpack
                                    (\_ -> revertPath (EntityList.getFullPath pageModel))
                                    (EntityList >> setPage)
                )

        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        SetLastKnownTimeStamp now ->
            map (\model -> { model | lastKnownCurrentTime = now })

        OnSubscriptionMsg msg_ ->
            Update.Subscription.update config msg_

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
            returnWith .page (updatePage config msg)


pageFL =
    fieldLens .page (\s b -> { b | page = s })


updatePage config msg page =
    case ( page, msg ) of
        ( EntityList model_, EntityListMsg msg_ ) ->
            andThen
                (\model ->
                    let
                        ( pageModel, cmd ) =
                            EntityList.update config
                                model
                                msg_
                                (pure model_)
                    in
                    ( { model | page = EntityList pageModel }, Cmd.map EntityListMsg cmd )
                )

        _ ->
            identity


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


createViewConfig : Model -> ViewConfig Msg
createViewConfig model =
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
    , onToggleEntitySelection = ToggleEntityIdSelection
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


view : Model -> Html Msg
view model =
    let
        config =
            createViewConfig model

        frame titleColorTuple pageContent =
            let
                frameVM =
                    ViewModel.Frame.frameVM config model titleColorTuple pageContent
            in
            View.Frame.frame frameVM
    in
    case getPage__ model of
        EntityList pageModel ->
            let
                pageVM =
                    ViewModel.EntityList.pageVM config model pageModel

                titleColorTuple =
                    EntityList.getTitleColourTuple pageModel
            in
            Views.EntityList.view pageVM |> frame titleColorTuple


getPage__ =
    .page


delta2hash =
    let
        getPathFromModel model =
            case getPage__ model of
                EntityList pageModel ->
                    EntityList.getFullPath pageModel

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


main : RouteUrl.RouteUrlProgram Flags Model Msg
main =
    let
        init =
            createAppModel
                >> update_ (OnFirebaseMsg OnFB_SwitchToNewUserSetupModeIfNeeded)

        update_ : Msg -> Model -> ( Model, Cmd Msg )
        update_ msg model =
            let
                updateConfig =
                    createUpdateConfig model
            in
            model |> pure >> update updateConfig msg
    in
    RouteUrl.programWithFlags
        { delta2url = delta2hash
        , location2messages =
            hash2messages
                { navigateToPathMsg = navigateToPathMsg
                }
        , init = init
        , update = update_
        , view = view
        , subscriptions = subscriptions
        }
