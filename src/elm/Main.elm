module Main exposing (main)

import AppDrawer.Model
import AppDrawer.Types exposing (AppDrawerMsg(..))
import Data.TodoDoc exposing (..)
import Data.User
import Document exposing (..)
import Entity exposing (..)
import EntityId
import ExclusiveMode.Types exposing (..)
import ExclusiveMode.Update as UExclusiveMode
import Firebase.Model exposing (FirebaseModel)
import Firebase.Update exposing (..)
import GroupDoc exposing (..)
import Html exposing (Html, text)
import Json.Encode as E
import Material
import Maybe.Extra
import Menu
import Menu.Types
import Models.Selection
import Models.TodoDocStore as TodoDocStore
import Navigation
import Overlays.MainMenu exposing (MainMenuMsg(..))
import Pages.EntityList as EntityList
import Ports
import Ports.Todo
import Random.Pcg
import RouteUrl
import RouteUrl.Builder
import Set exposing (Set)
import Stores
import Time exposing (Time)
import Todo.FormTypes
import Todo.ReminderOverlay.Model
import Todo.ReminderOverlay.Types exposing (TodoReminderOverlayModel)
import Toolkit.Operators exposing (..)
import Update.AppDrawer
import Update.GroupDoc exposing (..)
import Update.Keyboard as UKeyboard
import Update.Todo exposing (TodoMsg)
import ViewModel.EntityList
import ViewModel.Frame
import Views.EntityList
import Views.Frame
import Views.Landing
import X.Function.Infix exposing (..)
import X.Random
import X.Record exposing (..)
import X.Return exposing (..)
import X.Set
import XUpdate


type Page
    = EntityList EntityList.Model
    | LandingPage


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
    , selectedEntityIdSet : Set DocId
    , config : AppConfig
    , appDrawerModel : AppDrawer.Model.AppDrawerModel
    , mdl : Material.Model
    }


type alias ModelF =
    Model -> Model


editModeL =
    fieldLens .editMode (\s b -> { b | editMode = s })


pageL =
    fieldLens .page (\s b -> { b | page = s })


setEntityListPageModel : EntityList.Model -> ModelF
setEntityListPageModel pageModel =
    set pageL (EntityList pageModel)


type Msg
    = NOOP
    | OnRevertExclusiveMode
    | OnDebugPort String
    | OnKeyboardMsg UKeyboard.Msg
    | OnExclusiveModeMsg UExclusiveMode.Msg
    | OnMainMenuMsg MainMenuMsg
    | OnEntityListMsg EntityList.Msg
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
    | OnClearEntitySelection
    | OnStoresMsg Stores.Msg


navigateToPathMsg =
    NavigateToPath


onGoToEntityIdMsg =
    EntityList.OnGoToEntityId >> OnEntityListMsg


onStartAddingTodoWithFocusInEntityAsReferenceOld : Model -> Msg
onStartAddingTodoWithFocusInEntityAsReferenceOld model =
    case model.page of
        EntityList pageModel ->
            EntityList.getMaybeLastKnownFocusedEntityId pageModel
                |> Update.Todo.onStartAddingTodoWithFocusInEntityAsReference
                |> OnTodoMsg

        LandingPage ->
            NOOP


revertExclusiveModeMsg =
    OnRevertExclusiveMode


onSaveExclusiveModeForm : Msg
onSaveExclusiveModeForm =
    UExclusiveMode.OnSaveExclusiveModeForm |> OnExclusiveModeMsg


setFocusInEntityWithEntityIdMsg : EntityId -> Msg
setFocusInEntityWithEntityIdMsg =
    EntityList.OnSetCursorEntityId >> OnEntityListMsg


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        everyXSeconds x =
            Time.every (Time.second * x * debugSecondMultiplier)

        debugSecondMultiplier =
            --            if model.config.debug then
            --                60
            --            else
            1
    in
    Sub.batch
        [ Ports.debugPort OnDebugPort
        , everyXSeconds 60 SetLastKnownTimeStamp
        , UKeyboard.subscriptions |> Sub.map OnKeyboardMsg
        , Stores.subscriptions |> Sub.map OnStoresMsg
        , Sub.batch
            [ Ports.Todo.notificationClicked Update.Todo.OnReminderNotificationClicked

            -- note: 60 seconds is so that we can received any updates from firebase
            -- before triggering and changing any stale overdue todos timestamps.
            , everyXSeconds 60 (\_ -> Update.Todo.OnProcessPendingNotificationCronTick)
            ]
            |> Sub.map OnTodoMsg
        , Firebase.Update.subscriptions |> Sub.map OnFirebaseMsg
        , Update.AppDrawer.subscriptions |> Sub.map OnAppDrawerMsg
        ]


type alias Flags =
    { now : Time
    , encodedLists :
        { todo : List E.Value
        , project : List E.Value
        , context : List E.Value
        }
    , config : AppConfig
    }


initModel : Flags -> ( Model, Cmd msg )
initModel flags =
    let
        { now } =
            flags

        { deviceId, initialOfflineStore } =
            flags.config

        ( { todoStore, projectStore, contextStore }, seed ) =
            Stores.initialValue now deviceId flags.encodedLists

        ( initialPage, entityListCmd ) =
            EntityList.initialValue |> Tuple.mapFirst EntityList

        model : Model
        model =
            { lastKnownCurrentTime = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = XMNone
            , page = initialPage
            , reminderOverlay = Todo.ReminderOverlay.Model.none
            , firebaseModel = Firebase.Model.initialValue deviceId initialOfflineStore
            , selectedEntityIdSet = Set.empty
            , config = flags.config
            , appDrawerModel = AppDrawer.Model.initialValue initialOfflineStore
            , mdl = Material.model
            }
    in
    ( model, entityListCmd )


type alias UpdateConfig msg =
    Overlays.MainMenu.Config msg
        (UExclusiveMode.Config msg
            (Firebase.Update.Config msg
                (UKeyboard.Config msg
                    (Update.Todo.Config msg
                        (Update.GroupDoc.Config msg
                            { navigateToPathMsg : List String -> msg
                            }
                        )
                    )
                )
            )
        )


createUpdateConfig : Model -> UpdateConfig Msg
createUpdateConfig model =
    { onStartAddingTodoToInbox = Update.Todo.onStartAddingTodoToInbox |> OnTodoMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onSetExclusiveMode = UExclusiveMode.OnSetExclusiveMode >> OnExclusiveModeMsg
    , revertExclusiveModeMsg = revertExclusiveModeMsg
    , onStartSetupAddTodo = Update.Todo.onStartSetupAddTodo |> OnTodoMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , saveTodoFormMsg = Update.Todo.OnSaveTodoForm >> OnTodoMsg
    , saveGroupDocFormMsg = OnSaveGroupDocForm >> OnGroupDocMsg
    , focusNextEntityMsgNew = EntityList.OnMoveFocusBy 1 |> OnEntityListMsg
    , clearSelectionMsg = OnClearEntitySelection
    , focusPrevEntityMsgNew = EntityList.OnMoveFocusBy -1 |> OnEntityListMsg
    , navigateToPathMsg = navigateToPathMsg
    , goToEntityIdCmd = onGoToEntityIdMsg >> toCmd
    , isTodoStoreEmpty = TodoDocStore.isStoreEmpty model
    , recomputeEntityListCursorAfterStoreUpdated = EntityList.OnFocusListCursorAfterChangesReceivedFromPouchDBMsg |> OnEntityListMsg
    }


updateAll : List Msg -> ReturnF Msg Model
updateAll msgList ret =
    List.foldl (\msg ret -> ret |> andThenUpdate msg) ret msgList


updateChild childMsgWrapper childUpdateFn childL model =
    updateChildHelp
        childMsgWrapper
        (childUpdateFn (get childL model))
        (set childL)
        model


updateChildHelp :
    (msg -> Msg)
    -> XUpdate.Return model msg Msg
    -> (model -> ModelF)
    -> Model
    -> Return Msg Model
updateChildHelp childMsgWrapper childReturn setChild model =
    childReturn
        |> (\( childModel, cmdList, msgList ) ->
                ( setChild childModel model
                , Cmd.batch cmdList |> Cmd.map childMsgWrapper
                )
                    |> updateAll msgList
           )


andThenUpdate =
    update >> andThen


update : Msg -> Model -> Return Msg Model
update msg model =
    let
        config =
            createUpdateConfig model

        defRet =
            pure model
    in
    defRet |> updateReturnF config msg


updateReturnF : UpdateConfig Msg -> Msg -> ReturnF Msg Model
updateReturnF config msg =
    case msg of
        NOOP ->
            identity

        OnRevertExclusiveMode ->
            returnMsgAsCmd (OnExclusiveModeMsg UExclusiveMode.OnRevertExclusiveMode)
                >> returnMsgAsCmd (OnEntityListMsg EntityList.OnFocusEntityList)

        OnDebugPort cmdString ->
            case cmdString of
                "startOverdueCron" ->
                    Update.Todo.OnProcessPendingNotificationCronTick
                        |> OnTodoMsg
                        |> returnMsgAsCmd

                _ ->
                    identity

        ToggleEntityIdSelection entityId ->
            map
                (Models.Selection.updateSelectedEntityIdSet
                    (X.Set.toggleSetMember (getDocIdFromEntityId entityId))
                )

        OnClearEntitySelection ->
            map Models.Selection.clearSelection

        NavigateToPath path ->
            onNavigateToPath path

        OnStoresMsg storeMsg ->
            let
                toStoreModel { todoStore, contextStore, projectStore } =
                    Stores.fromStores todoStore contextStore projectStore

                storesF =
                    fieldLens toStoreModel
                        (\s b ->
                            { b
                                | todoStore = s.todoStore
                                , contextStore = s.contextStore
                                , projectStore = s.projectStore
                            }
                        )
            in
            andThen
                (updateChild OnStoresMsg
                    (Stores.update config storeMsg)
                    storesF
                )

        OnMdl msg_ ->
            andThen (Material.update OnMdl msg_)

        SetLastKnownTimeStamp now ->
            map (\model -> { model | lastKnownCurrentTime = now })

        OnKeyboardMsg msg_ ->
            andThen
                (\model ->
                    pure model |> updateAll (UKeyboard.update config model msg_)
                )

        OnGroupDocMsg msg_ ->
            returnWithNow (OnGroupDocMsgWithNow msg_)

        OnGroupDocMsgWithNow msg_ now ->
            Update.GroupDoc.update config now msg_

        OnExclusiveModeMsg msg_ ->
            --UExclusiveMode.update config msg_
            andThen
                (updateChild OnExclusiveModeMsg
                    (UExclusiveMode.update config msg_)
                    editModeL
                )

        OnMainMenuMsg msg_ ->
            Overlays.MainMenu.update config msg_

        OnTodoMsg msg_ ->
            returnWithNow (OnTodoMsgWithNow msg_)

        OnTodoMsgWithNow msg_ now ->
            Update.Todo.update config now msg_

        OnFirebaseMsg msg_ ->
            let
                firebaseModelL =
                    fieldLens .firebaseModel (\s b -> { b | firebaseModel = s })
            in
            andThen
                (updateChild OnFirebaseMsg
                    (Firebase.Update.update config msg_)
                    firebaseModelL
                )

        OnAppDrawerMsg msg_ ->
            let
                appDrawerModel =
                    fieldLens .appDrawerModel (\s b -> { b | appDrawerModel = s })
            in
            overReturnFMapCmd appDrawerModel OnAppDrawerMsg (Update.AppDrawer.update msg_)

        _ ->
            andThen (updatePage config msg)


onNavigateToPath path =
    let
        setPage page =
            map (set pageL page)
                >> map Models.Selection.clearSelection
                >> andThenUpdate revertExclusiveModeMsg

        revertPath path =
            path
                |> String.join "/"
                |> (++) "#!/"
                |> Navigation.modifyUrl
                |> command

        currentPagePath page =
            case page of
                EntityList pageModel ->
                    EntityList.getPath pageModel

                LandingPage ->
                    []

        revertPathOnNoMatchCommand page =
            currentPagePath page |> revertPath
    in
    returnWith .page
        (\page ->
            case path of
                [] ->
                    setPage LandingPage

                _ ->
                    let
                        setEntityListPageOrRevertPath maybePageModel =
                            EntityList.maybeInitFromPath path maybePageModel
                                |> Maybe.Extra.unpack
                                    (\_ -> revertPathOnNoMatchCommand page)
                                    (\( pageModel, pageCmd ) ->
                                        setPage (EntityList pageModel)
                                            >> command pageCmd
                                    )
                    in
                    case page of
                        EntityList pageModel ->
                            setEntityListPageOrRevertPath (Just pageModel)

                        _ ->
                            setEntityListPageOrRevertPath Nothing
        )


updatePage config msg model =
    case ( model.page, msg ) of
        ( EntityList pageModel, OnEntityListMsg pageMsg ) ->
            updateChildHelp
                OnEntityListMsg
                (EntityList.update config model pageMsg pageModel)
                setEntityListPageModel
                model

        _ ->
            model ! []


type alias ViewConfig msg =
    { noop : msg
    , onAppDrawerMsg : AppDrawer.Types.AppDrawerMsg -> msg
    , onFirebaseMsg : FirebaseMsg -> msg
    , onMainMenuStateChanged : Menu.Types.MenuState -> msg
    , onMdl : Material.Msg msg -> msg
    , onReminderOverlayAction : Todo.ReminderOverlay.Model.Action -> msg
    , onGoToTodoDocIdMsg : DocId -> msg
    , onSaveExclusiveModeForm : msg
    , onSetContext : DocId -> ContextDoc -> msg
    , onSetProject : DocId -> ProjectDoc -> msg
    , onSetTodoFormMenuState : Todo.FormTypes.TodoForm -> Menu.State -> msg
    , onSetTodoFormReminderDate : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormReminderTime : Todo.FormTypes.TodoForm -> String -> msg
    , onSetTodoFormText : Todo.FormTypes.TodoForm -> String -> msg
    , onShowMainMenu : msg
    , onSignInMsg : msg
    , onSignOutMsg : msg
    , onSkipSignInMsg : msg
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
    , revertExclusiveModeMsg : msg
    , setFocusInEntityWithEntityId : Entity.EntityId -> msg
    , updateGroupDocFromNameMsg :
        GroupDocForm -> GroupDocName -> msg
    , maybeEntityIdAtCursorOld : Maybe EntityId
    , maybeCursorEntityId : Maybe EntityId
    , navigateToPathMsg : List String -> msg
    , maybeUser : Data.User.MaybeUser
    , mdl : Material.Model

    --    , maybeUserId: Data.User.MaybeUID
    }


createViewConfig : Model -> ViewConfig Msg
createViewConfig model =
    { onSetProject = Update.Todo.onSetProjectAndMaybeSelectionMsg >>> OnTodoMsg
    , onSetContext = Update.Todo.onSetContextAndMaybeSelectionMsg >>> OnTodoMsg
    , onSetTodoFormMenuState = Update.Todo.onSetTodoFormMenuStateMsg >>> OnTodoMsg
    , noop = NOOP
    , revertExclusiveModeMsg = revertExclusiveModeMsg
    , onSetTodoFormText = Update.Todo.onSetTodoFormTextMsg >>> OnTodoMsg
    , onToggleDeleted = Update.Todo.onToggleDeletedMsg >> OnTodoMsg
    , onSetTodoFormReminderDate = Update.Todo.onSetTodoFormReminderDateMsg >>> OnTodoMsg
    , onSetTodoFormReminderTime = Update.Todo.onSetTodoFormReminderTimeMsg >>> OnTodoMsg
    , onSaveExclusiveModeForm = onSaveExclusiveModeForm
    , onMainMenuStateChanged = OnMainMenuStateChanged >> OnMainMenuMsg
    , onSignInMsg = OnFirebaseMsg OnFBSignIn
    , onSkipSignInMsg = OnFirebaseMsg OnFBSkipSignIn
    , onSignOutMsg = OnFirebaseMsg OnFBSignOut
    , onFirebaseMsg = OnFirebaseMsg
    , onReminderOverlayAction = Update.Todo.onReminderOverlayActionMsg >> OnTodoMsg
    , onGoToTodoDocIdMsg = EntityId.fromTodoDocId >> onGoToEntityIdMsg
    , onToggleAppDrawerOverlay = OnAppDrawerMsg AppDrawer.Types.OnToggleOverlay
    , onAppDrawerMsg = OnAppDrawerMsg
    , onStartAddingGroupDoc = OnGroupDocAction # GDA_StartAdding >> OnGroupDocMsg
    , onMdl = OnMdl
    , onShowMainMenu = OnShowMainMenu |> OnMainMenuMsg
    , onStartAddingTodoWithFocusInEntityAsReference =
        onStartAddingTodoWithFocusInEntityAsReferenceOld model
    , onToggleEntitySelection = ToggleEntityIdSelection
    , onStartEditingTodoProject = Update.Todo.onStartEditingTodoProjectMsg >> OnTodoMsg
    , onStartEditingTodoContext = Update.Todo.onStartEditingTodoContextMsg >> OnTodoMsg
    , onStartEditingTodoText = Update.Todo.onStartEditingTodoTextMsg >> OnTodoMsg
    , onStartEditingReminder = Update.Todo.onStartEditingReminderMsg >> OnTodoMsg
    , onToggleDeletedAndMaybeSelection =
        Update.Todo.onToggleDeletedAndMaybeSelectionMsg >> OnTodoMsg
    , onToggleDoneAndMaybeSelection =
        Update.Todo.onToggleDoneAndMaybeSelectionMsg >> OnTodoMsg
    , onToggleGroupDocArchived = toggleGroupDocArchivedMsg >> OnGroupDocMsg
    , updateGroupDocFromNameMsg =
        updateGroupDocFromNameMsg >>> OnGroupDocMsg
    , onStartEditingGroupDoc = startEditingGroupDocMsg >> OnGroupDocMsg
    , setFocusInEntityWithEntityId = setFocusInEntityWithEntityIdMsg
    , maybeEntityIdAtCursorOld = Nothing
    , maybeCursorEntityId = Nothing
    , navigateToPathMsg = navigateToPathMsg
    , maybeUser = Firebase.Model.getMaybeUser model.firebaseModel
    , mdl = model.mdl

    --          , maybeUserId =  Firebase.getMaybeUser
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
            Views.Frame.init frameVM
    in
    case model.page of
        LandingPage ->
            Views.Landing.view

        EntityList pageModel ->
            let
                pageVM =
                    ViewModel.EntityList.pageVM config model pageModel

                titleColorTuple =
                    EntityList.getTitleColourTuple pageModel
            in
            Views.EntityList.view pageVM |> frame titleColorTuple


delta2hash =
    let
        getPathFromModel previousModel currentModel =
            case currentModel.page of
                EntityList pageModel ->
                    EntityList.getPath pageModel

                LandingPage ->
                    [ "" ]

        delta2builder previousModel currentModel =
            RouteUrl.Builder.builder
                |> RouteUrl.Builder.replacePath (getPathFromModel previousModel currentModel)
    in
    delta2builder >>> RouteUrl.Builder.toHashChange >> Just


hash2messages config location =
    let
        builder =
            RouteUrl.Builder.fromHash location.href

        path =
            RouteUrl.Builder.path builder
    in
    [ navigateToPathMsg path ]


main : RouteUrl.RouteUrlProgram Flags Model Msg
main =
    let
        init flags =
            let
                ( model, cmd ) =
                    initModel flags
            in
            update (OnFirebaseMsg OnFBSwitchToNewUserSetupModeIfNeeded) model
                |> command cmd
    in
    RouteUrl.programWithFlags
        { delta2url = delta2hash
        , location2messages =
            hash2messages
                { navigateToPathMsg = navigateToPathMsg
                }
        , init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
