module Model exposing (..)

import AppDrawer.Model
import CommonMsg
import Context
import Dict.Extra
import Document exposing (Document)
import Entity.Tree
import ExclusiveMode exposing (ExclusiveMode)
import Entity exposing (Entity)
import Firebase.SignIn
import X.Keyboard as Keyboard exposing (KeyboardEvent)
import X.List as List
import X.Predicate as Pred
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Firebase exposing (DeviceId)
import GroupDoc
import Http
import Keyboard.Combo exposing (combo1, combo2, combo3)
import Keyboard.Combo as Combo
import LaunchBar.Form
import Menu
import Project
import ReminderOverlay
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import X.Random as Random
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import Random.Pcg as Random exposing (Seed)
import Return
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.Msg
import Todo.NewForm
import Todo.ReminderForm
import Todo.Store
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import LaunchBar
import Todo.GroupForm
import Todo.TimeTracker


type Msg
    = NOOP
    | OnCommonMsg CommonMsg.Msg
    | OnPouchDBChange String D.Value
    | OnEntityUpsert Entity
    | OnFirebaseChange String D.Value
    | OnUserChanged Firebase.User
    | AfterUserChanged
    | OnFCMTokenChanged Firebase.FCMToken
    | OnFirebaseConnectionChanged Bool
    | OnSignIn
    | SignOut
    | RemotePouchSync ExclusiveMode.SyncForm
    | TodoAction Todo.UpdateAction Todo.Id
    | ReminderOverlayAction ReminderOverlay.Action
    | ToggleShowDeletedEntity
    | ToggleDrawer
    | OnLayoutNarrowChanged Bool
    | ToggleTodoDone Todo.Id
    | SetTodoContext Context.Model Todo.Model
    | SetTodoProject Project.Model Todo.Model
    | NewTodo
    | NewTodoForInbox
    | NewProject
    | NewContext
    | NewTodoTextChanged Todo.NewForm.Model Todo.Text
    | OnDeactivateEditingMode
    | OnSkipSignIn
    | OnCreateDefaultEntities
    | OnCreateDefaultEntitiesWithResult (Result Http.Error D.Value)
    | StartEditingReminder Todo.Model
    | StartEditingContext Todo.Model
    | StartEditingProject Todo.Model
    | OnSaveCurrentForm
    | UpdateRemoteSyncFormUri ExclusiveMode.SyncForm String
    | OnEditTodoProjectMenuStateChanged Todo.GroupForm.Model Menu.State
    | OnEditTodoContextMenuStateChanged Todo.GroupForm.Model Menu.State
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | OnEntityListKeyDown (List Entity) KeyboardEvent
    | OnSetViewType ViewType
    | OnSetEntityListView EntityListViewType
    | OnNowChanged Time
    | OnKeyboardMsg Keyboard.Msg
    | OnGlobalKeyUp Keyboard.Key
    | OnEntityAction Entity Entity.Action
    | OnLaunchBarMsg LaunchBar.Action
    | OnLaunchBarMsgWithNow LaunchBar.Action Time
    | OnTaskMsg Todo.Msg.Msg
    | OnTaskMsgWithTime Todo.Msg.Msg Time
    | OnFirebaseMsg Firebase.Msg
    | OnFirebaseMsgWithTime Firebase.Msg Time
    | OnKeyCombo Combo.Msg
    | OnCloseNotification String
    | OnSetDomFocusToFocusInEntity
    | OnAppDrawerMsg AppDrawer.Model.Msg
    | OnPersistLocalPref


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ combo2 ( Combo.shift, Combo.s ) (onTodoStopRunning)
    , combo2 ( Combo.shift, Combo.p ) (onTodoTogglePaused)
    , combo2 ( Combo.shift, Combo.r ) (onGotoRunningTodo)
    ]


onTodoToggleRunning =
    Todo.Msg.ToggleRunning >> OnTaskMsg


onTodoInitRunning =
    Todo.Msg.InitRunning >> OnTaskMsg


onTodoStopRunning =
    Todo.Msg.StopRunning |> OnTaskMsg


onTodoTogglePaused =
    Todo.Msg.TogglePaused |> OnTaskMsg


onGotoRunningTodo =
    Todo.Msg.GotoRunning |> OnTaskMsg


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg


noop =
    commonMsg.noOp


type alias EntityListViewType =
    Entity.ListViewType


type ViewType
    = EntityListView EntityListViewType
    | SyncView


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editMode : ExclusiveMode
    , mainViewType : ViewType
    , keyboardState : Keyboard.State
    , showDeleted : Bool
    , reminderOverlay : ReminderOverlay.Model
    , pouchDBRemoteSyncURI : String
    , user : Firebase.User
    , fcmToken : Firebase.FCMToken
    , developmentMode : Bool
    , selectedEntityIdSet : Set Document.Id
    , layout : Layout
    , appVersion : String
    , deviceId : String
    , firebaseClient : Firebase.Client
    , focusInEntity : Entity.Entity
    , timeTracker : Todo.TimeTracker.Model
    , keyComboModel : Keyboard.Combo.Model Msg
    , config : Config
    , appDrawerModel : AppDrawer.Model.Model
    , signInModel : Firebase.SignIn.Model
    }


type alias Layout =
    { narrow : Bool
    , forceNarrow : Bool
    }


type alias ModelF =
    Model -> Model


type alias Config =
    { isFirstVisit : Bool
    }


type alias LocalPref =
    { appDrawer : AppDrawer.Model.Model
    , signIn : Firebase.SignIn.Model
    }


localPrefDecoder =
    D.succeed LocalPref
        |> D.optional "appDrawer" AppDrawer.Model.decode AppDrawer.Model.default
        |> D.optional "signIn" Firebase.SignIn.decoder Firebase.SignIn.default


encodeLocalPref model =
    E.object
        [ "appDrawer" => AppDrawer.Model.encode model.appDrawerModel
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
    , config : Config
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


contextStore =
    X.Record.field .contextStore (\s b -> { b | contextStore = s })


projectStore =
    X.Record.field .projectStore (\s b -> { b | projectStore = s })


todoStore =
    X.Record.field .todoStore (\s b -> { b | todoStore = s })


keyboardState =
    X.Record.field .keyboardState (\s b -> { b | keyboardState = s })


now =
    X.Record.field .now (\s b -> { b | now = s })


firebaseClient =
    X.Record.field .firebaseClient (\s b -> { b | firebaseClient = s })


editMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


user =
    X.Record.field .user (\s b -> { b | user = s })


focusInEntity =
    X.Record.field .focusInEntity (\s b -> { b | focusInEntity = s })


keyComboModel =
    X.Record.field .keyComboModel (\s b -> { b | keyComboModel = s })


init : Flags -> Return.Return Msg Model
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

        firebaseClient =
            Firebase.initClient flags.deviceId

        localPref =
            D.decodeValue localPrefDecoder flags.localPref
                |> Result.mapError (Debug.log "Unable to decode localPref")
                != defaultLocalPref

        editMode =
            if Firebase.SignIn.shouldSkipSignIn localPref.signIn then
                -- ExclusiveMode.initActionList
                ExclusiveMode.none
            else
                ExclusiveMode.firstVisit

        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = editMode
            , mainViewType = defaultView
            , keyboardState = Keyboard.init
            , showDeleted = False
            , reminderOverlay = ReminderOverlay.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , user = Firebase.NotLoggedIn
            , fcmToken = Nothing
            , developmentMode = flags.developmentMode
            , selectedEntityIdSet = Set.empty
            , layout = { narrow = False, forceNarrow = False }
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity = inboxEntity
            , timeTracker = Todo.TimeTracker.none
            , firebaseClient = firebaseClient
            , keyComboModel =
                Keyboard.Combo.init
                    { toMsg = OnKeyCombo
                    , combos = keyboardCombos
                    }
            , config = flags.config
            , appDrawerModel = localPref.appDrawer
            , signInModel = localPref.signIn
            }
    in
        model |> Return.singleton


defaultView =
    EntityListView Entity.defaultListView


type alias ReturnF =
    Return.Return Msg Model -> Return.Return Msg Model


inboxEntity =
    Entity.fromContext Context.null


getMaybeUserProfile =
    .user >> Firebase.getMaybeUserProfile


getMaybeUserId =
    .user >> Firebase.getMaybeUserId


setUser =
    set user


setFCMToken fcmToken model =
    { model | fcmToken = fcmToken }
        |> over firebaseClient (Firebase.updateToken fcmToken)


updateFirebaseConnection connected =
    over firebaseClient (Firebase.updateConnection connected)


toggleLayoutForceNarrow =
    updateLayout (\layout -> { layout | forceNarrow = not layout.forceNarrow })


setLayoutNarrow narrow =
    updateLayout (\layout -> { layout | narrow = narrow })


getLayoutForceNarrow =
    .layout >> .forceNarrow


isLayoutAutoNarrow : Model -> Bool
isLayoutAutoNarrow =
    getLayout
        >> apply2 ( .forceNarrow >> not, .narrow )
        >> uncurry and


filterTodosAndSortBy pred sortBy model =
    Store.filterDocs pred model.todoStore
        |> List.sortBy sortBy


filterTodosAndSortByLatestCreated pred =
    filterTodosAndSortBy pred (Todo.getCreatedAt >> negate)


filterTodosAndSortByLatestModified pred =
    filterTodosAndSortBy pred (Todo.getModifiedAt >> negate)


filterContexts pred model =
    Store.filterDocs pred model.contextStore
        |> List.append (Context.filterNull pred)
        |> Context.sort


filterProjects pred model =
    Store.filterDocs pred model.projectStore
        |> List.append (Project.filterNull pred)
        |> Project.sort


currentDocPredicate model =
    if model.showDeleted then
        Document.isDeleted
    else
        Document.isNotDeleted


filterCurrentContexts model =
    filterContexts (currentDocPredicate model) model


filterCurrentProjects model =
    filterProjects (currentDocPredicate model) model


isTodoContextActive model =
    Todo.getContextId
        >> findContextByIdIn model
        >>? GroupDoc.isActive
        >>?= True


isTodoProjectActive model =
    Todo.getProjectId
        >> findProjectByIdIn model
        >>? GroupDoc.isActive
        >>?= True


getActiveTodoListHavingActiveContexts model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProjects model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoProjectActive model ])


getActiveTodoListForContext context model =
    filterTodosAndSortByLatestCreated
        (Pred.all
            [ Todo.isActive
            , Todo.contextFilter context
            , isTodoProjectActive model
            ]
        )
        model


getActiveTodoListForProject project model =
    filterTodosAndSortByLatestCreated
        (Pred.all
            [ Todo.isActive
            , Todo.hasProject project
            , isTodoContextActive model
            ]
        )
        model


createGrouping : Entity.ListViewType -> Model -> Entity.Tree.Tree
createGrouping viewType model =
    let
        getActiveTodoListForContextHelp =
            getActiveTodoListForContext # model

        getActiveTodoListForProjectHelp =
            getActiveTodoListForProject # model

        findProjectByIdHelp =
            findProjectById # model

        findContextByIdHelp =
            findContextById # model
    in
        case viewType of
            Entity.ContextsView ->
                getActiveContexts model
                    |> Entity.Tree.initContextForest
                        getActiveTodoListForContextHelp

            Entity.ProjectsView ->
                getActiveProjects model
                    |> Entity.Tree.initProjectForest
                        getActiveTodoListForProjectHelp

            Entity.ContextView id ->
                findContextById id model
                    ?= Context.null
                    |> Entity.Tree.initContextRoot
                        getActiveTodoListForContextHelp
                        findProjectByIdHelp

            Entity.ProjectView id ->
                findProjectById id model
                    ?= Project.null
                    |> Entity.Tree.initProjectRoot
                        getActiveTodoListForProjectHelp
                        findContextByIdHelp

            Entity.BinView ->
                Entity.Tree.initTodoForest
                    "Bin"
                    (filterTodosAndSortByLatestModified Document.isDeleted model)

            Entity.DoneView ->
                Entity.Tree.initTodoForest
                    "Done"
                    (filterTodosAndSortByLatestModified
                        (Pred.all [ Document.isNotDeleted, Todo.isDone ])
                        model
                    )

            Entity.RecentView ->
                Entity.Tree.initTodoForest
                    "Recent"
                    (filterTodosAndSortByLatestModified Pred.always model)


getActiveTodoListWithReminderTime model =
    model.todoStore |> Store.filterDocs (Todo.isReminderOverdue model.now)


findTodoWithOverDueReminder model =
    model.todoStore |> Store.findBy (Todo.isReminderOverdue model.now)


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = ReminderOverlay.initialView todo }


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


removeReminderOverlay model =
    { model | reminderOverlay = ReminderOverlay.none }


setReminderOverlayToSnoozeView details model =
    { model | reminderOverlay = ReminderOverlay.snoozeView details }


snoozeTodoWithOffset snoozeOffset todoId model =
    let
        time =
            ReminderOverlay.addSnoozeOffset model.now snoozeOffset
    in
        model
            |> updateTodo (time |> Todo.SnoozeTill) todoId
            >> Tuple.mapFirst removeReminderOverlay


findAndSnoozeOverDueTodo : Model -> Maybe ( ( Todo.Model, Model ), Cmd msg )
findAndSnoozeOverDueTodo model =
    let
        snooze todoId =
            updateTodo (Todo.AutoSnooze model.now) todoId model
                |> (\( model, cmd ) ->
                        findTodoById todoId model ?|> (\todo -> ( ( todo, model ), cmd ))
                   )
    in
        Store.findBy (Todo.isReminderOverdue model.now) model.todoStore
            ?+> (Document.getId >> snooze)


createContext text model =
    model
        |> overT2 contextStore (Store.insert (Context.init text model.now))
        |> Tuple.second


createProject text model =
    model
        |> overT2 projectStore (Store.insert (Project.init text model.now))
        |> Tuple.second


createTodo text model =
    model
        |> insertTodo (Todo.init model.now text)
        |> Tuple.second


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


isShowDetailsKeyPressed =
    .keyboardState >> Keyboard.isAltDown >> not


activateLaunchBar : Time -> ModelF
activateLaunchBar now =
    set editMode (LaunchBar.Form.create now |> ExclusiveMode.LaunchBar)


updateLaunchBarInput now text form =
    set editMode (LaunchBar.Form.updateInput now text form |> ExclusiveMode.LaunchBar)


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    set editMode (Todo.NewForm.create (model.focusInEntity) "" |> ExclusiveMode.NewTodo) model


activateNewTodoModeWithInboxAsReference : ModelF
activateNewTodoModeWithInboxAsReference =
    set editMode (Todo.NewForm.create inboxEntity "" |> ExclusiveMode.NewTodo)


updateNewTodoText form text =
    set editMode (Todo.NewForm.setText text form |> ExclusiveMode.NewTodo)


startEditingReminder : Todo.Model -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> ExclusiveMode.EditTodoReminder)


startEditingTodoProject : Todo.Model -> ModelF
startEditingTodoProject todo =
    setEditMode (Todo.GroupForm.init todo |> ExclusiveMode.EditTodoProject)


startEditingTodoContext : Todo.Model -> ModelF
startEditingTodoContext todo =
    setEditMode (Todo.GroupForm.init todo |> ExclusiveMode.EditTodoContext)


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    setEditMode (ExclusiveMode.createEntityEditForm entity) model


switchToEntityListViewFromEntity entity model =
    let
        maybeEntityListViewType =
            maybeGetCurrentEntityListViewType model
    in
        entity
            |> Entity.toViewType maybeEntityListViewType
            |> (setEntityListViewType # model)


updateEditModeNameChanged newName entity model =
    case model.editMode of
        ExclusiveMode.EditContext ecm ->
            setEditMode (ExclusiveMode.editContextSetName newName ecm) model

        ExclusiveMode.EditProject epm ->
            setEditMode (ExclusiveMode.editProjectSetName newName epm) model

        _ ->
            model


saveCurrentForm model =
    case model.editMode of
        ExclusiveMode.EditContext form ->
            model
                |> updateContext form.id
                    (Context.setName form.name)

        ExclusiveMode.EditProject form ->
            model
                |> updateProject form.id
                    (Project.setName form.name)

        ExclusiveMode.EditTask form ->
            model
                |> updateTodo (Todo.SetText form.todoText) form.id

        ExclusiveMode.EditTodoReminder form ->
            model
                |> updateTodo (Todo.SetScheduleFromMaybeTime (Todo.ReminderForm.getMaybeTime form)) form.id

        ExclusiveMode.EditTodoContext form ->
            model |> Return.singleton

        ExclusiveMode.EditTodoProject form ->
            model |> Return.singleton

        ExclusiveMode.TaskMoreMenu _ ->
            model |> Return.singleton

        ExclusiveMode.NewTodo form ->
            insertTodo (Todo.init model.now (form |> Todo.NewForm.getText)) model
                |> Tuple.mapFirst Document.getId
                |> uncurry
                    (\todoId ->
                        updateTodo
                            (case form.referenceEntity of
                                Entity.Task fromTodo ->
                                    (Todo.CopyProjectAndContextId fromTodo)

                                Entity.Group g ->
                                    case g of
                                        Entity.Context context ->
                                            (Todo.SetContext context)

                                        Entity.Project project ->
                                            (Todo.SetProject project)
                            )
                            todoId
                            >> Tuple.mapFirst (setFocusInEntityFromTodoId todoId)
                    )

        ExclusiveMode.EditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        ExclusiveMode.LaunchBar form ->
            model |> Return.singleton

        ExclusiveMode.ActionList _ ->
            model |> Return.singleton

        ExclusiveMode.None ->
            model |> Return.singleton

        ExclusiveMode.FirstVisit ->
            model |> Return.singleton


setFocusInEntityFromTodoId : Todo.Id -> ModelF
setFocusInEntityFromTodoId todoId model =
    maybe2Tuple ( findTodoById todoId model ?|> Entity.Task, Just model )
        ?|> uncurry setFocusInEntity
        ?= model


toggleDeleteEntity : Entity -> ModelReturnF msg
toggleDeleteEntity entity model =
    let
        entityId =
            getEntityId entity
    in
        model
            |> case entity of
                Entity.Group g ->
                    case g of
                        Entity.Context context ->
                            updateContext entityId Document.toggleDeleted

                        Entity.Project project ->
                            updateProject entityId Document.toggleDeleted

                Entity.Task todo ->
                    updateTodo (Todo.ToggleDeleted) entityId


toggleArchiveEntity : Entity -> ModelReturnF msg
toggleArchiveEntity entity model =
    let
        entityId =
            getEntityId entity
    in
        model
            |> case entity of
                Entity.Group g ->
                    case g of
                        Entity.Context context ->
                            updateContext entityId GroupDoc.toggleArchived

                        Entity.Project project ->
                            updateProject entityId GroupDoc.toggleArchived

                Entity.Task todo ->
                    updateTodo (Todo.ToggleDone) entityId


getMaybeEditTodoReminderForm model =
    case model.editMode of
        ExclusiveMode.EditTodoReminder form ->
            Just form

        _ ->
            Nothing


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                ExclusiveMode.EditSyncSettings form ->
                    Just form

                _ ->
                    Nothing
    in
        maybeForm ?= createRemoteSyncForm model


createRemoteSyncForm : Model -> ExclusiveMode.SyncForm
createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }


deactivateEditingMode =
    setEditMode ExclusiveMode.none


getEditMode : Model -> ExclusiveMode
getEditMode =
    (.editMode)


setEditMode : ExclusiveMode -> ModelF
setEditMode editMode =
    (\model -> { model | editMode = editMode })


updateEditModeM : (Model -> ExclusiveMode) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


clearSelection =
    setSelectedEntityIdSet Set.empty


findTodoById : Document.Id -> Model -> Maybe Todo.Model
findTodoById id =
    getTodoStore >> Store.findById id


findProjectById : Document.Id -> Model -> Maybe Project.Model
findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Project.null ] |> List.find (Document.hasId id)))


findProjectByIdIn =
    flip findProjectById


findContextById : Document.Id -> Model -> Maybe Context.Model
findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Context.null ] |> List.find (Document.hasId id)))


findContextByIdIn =
    flip findContextById


updateTodoAndMaybeAlsoSelected action todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId
    in
        model |> updateAllTodos action idSet


insertTodo : (DeviceId -> Document.Id -> Todo.Model) -> Model -> ( Todo.Model, Model )
insertTodo constructWithId =
    X.Record.overT2 todoStore (Store.insert (constructWithId))


setTodoStoreFromTuple tuple model =
    tuple |> Tuple.mapSecond (setTodoStore # model)


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromTask

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromProject

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromContext

        _ ->
            (\_ -> Nothing)


upsertEncodedDocOnFirebaseChange : String -> E.Value -> Model -> Cmd msg
upsertEncodedDocOnFirebaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            getTodoStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "project-db" ->
            getProjectStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "context-db" ->
            getContextStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        _ ->
            (\_ -> Cmd.none)


getMainViewType : Model -> ViewType
getMainViewType =
    (.mainViewType)


switchToView : ViewType -> ModelF
switchToView mainViewType model =
    { model | mainViewType = mainViewType }
        |> clearSelection


projectView =
    Document.getId >> Entity.ProjectView >> EntityListView


contextView =
    Document.getId >> Entity.ContextView >> EntityListView


switchToProjectView =
    projectView >> switchToView


switchToContextView =
    contextView >> switchToView


switchToContextsView =
    EntityListView Entity.ContextsView |> switchToView


setEntityListViewType =
    EntityListView >> switchToView


getEntityId =
    Entity.getId


getCurrentViewEntityList model =
    --todo: can use maybeGetCurrentEntityListViewType
    case model.mainViewType of
        EntityListView viewType ->
            createGrouping viewType model |> Entity.Tree.flatten

        _ ->
            []


maybeGetCurrentEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


getLayout : Model -> Layout
getLayout =
    (.layout)


setLayout : Layout -> ModelF
setLayout layout model =
    { model | layout = layout }


updateLayoutM : (Model -> Layout) -> ModelF
updateLayoutM updater model =
    setLayout (updater model) model


updateLayout : (Layout -> Layout) -> ModelF
updateLayout updater model =
    setLayout (updater (getLayout model)) model


toggleEntitySelection entity =
    updateSelectedEntityIdSet (toggleSetMember (getEntityId entity))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


getSelectedEntityIdSet : Model -> Set Document.Id
getSelectedEntityIdSet =
    (.selectedEntityIdSet)


setSelectedEntityIdSet : Set Document.Id -> ModelF
setSelectedEntityIdSet selectedEntityIdSet model =
    { model | selectedEntityIdSet = selectedEntityIdSet }


updateSelectedEntityIdSetM : (Model -> Set Document.Id) -> ModelF
updateSelectedEntityIdSetM updater model =
    setSelectedEntityIdSet (updater model) model


updateSelectedEntityIdSet : (Set Document.Id -> Set Document.Id) -> ModelF
updateSelectedEntityIdSet updater model =
    setSelectedEntityIdSet (updater (getSelectedEntityIdSet model)) model


getTodoStore : Model -> Todo.Store
getTodoStore =
    (.todoStore)


setTodoStore : Todo.Store -> ModelF
setTodoStore todoStore model =
    { model | todoStore = todoStore }


updateTodoStore : (Todo.Store -> Todo.Store) -> ModelF
updateTodoStore updater model =
    { model | todoStore = getTodoStore model |> updater }


getProjectStore : Model -> Project.Store
getProjectStore =
    (.projectStore)


setProjectStore : Project.Store -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


setProjectStoreIn =
    flip setProjectStore


updateProjectStore : (Project.Store -> Project.Store) -> ModelF
updateProjectStore updater model =
    setProjectStore (updater (getProjectStore model)) model


updateProjectStoreM : (Model -> Project.Store) -> ModelF
updateProjectStoreM updater model =
    setProjectStore (updater model) model


getContextStore : Model -> Context.Store
getContextStore =
    (.contextStore)


setContextStore : Context.Store -> ModelF
setContextStore contextStore model =
    { model | contextStore = contextStore }


setContextStoreIn =
    flip setContextStore


updateContextStoreM : (Model -> Context.Store) -> ModelF
updateContextStoreM updater model =
    setContextStore (updater model) model


getNow : Model -> Time
getNow =
    (.now)


setNow : Time -> ModelF
setNow now model =
    { model | now = now }


updateNowM : (Model -> Time) -> ModelF
updateNowM updater model =
    { model | now = updater model }


getKeyboardState : Model -> Keyboard.State
getKeyboardState =
    (.keyboardState)


setKeyboardState : Keyboard.State -> ModelF
setKeyboardState keyboardState model =
    { model | keyboardState = keyboardState }


updateKeyboardStateM : (Model -> Keyboard.State) -> ModelF
updateKeyboardStateM updater model =
    setKeyboardState (updater model) model


updateKeyboardState : (Keyboard.State -> Keyboard.State) -> ModelF
updateKeyboardState updater model =
    setKeyboardState (updater (getKeyboardState model)) model



-- Focus Functions


setFocusInEntity entity =
    set focusInEntity entity


getMaybeFocusInEntityIndex entityList model =
    entityList
        |> List.findIndex (Entity.equalById model.focusInEntity)


getMaybeFocusInEntity entityList model =
    entityList
        |> List.find (Entity.equalById model.focusInEntity)
        |> Maybe.orElse (List.head entityList)


moveFocusBy : Int -> List Entity -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity



-- Document Query Helpers


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive


getContextsAsIdDict =
    (.contextStore) >> Store.asIdDict


getProjectsAsIdDict =
    (.projectStore) >> Store.asIdDict



-- Document Update Helpers


type alias Return msg =
    Return.Return msg Model


type alias ModelReturnF msg =
    Model -> Return msg


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateAllNamedDocsDocs idSet updateFn store model =
    X.Record.overT2 store
        (Store.updateAndPersist
            (Document.getId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
        |> Tuple2.swap
        |> Return.map (updateEntityListCursorOnGroupDocChange model)


updateEntityListCursorOnGroupDocChange oldModel newModel =
    let
        updateEntityListCursorFromEntityIndexTuple model indexTuple =
            let
                setFocusInEntityByIndex index entityList model =
                    List.clampIndex index entityList
                        |> (List.getAt # entityList)
                        |> Maybe.orElse (List.head entityList)
                        |> maybeSetIn model focusInEntity

                setFocusInIndex index =
                    setFocusInEntityByIndex
                        index
                        (getCurrentViewEntityList model)
            in
                model
                    |> case indexTuple of
                        -- not we want focus to remain on group entity, when edited, since its sort order may change. But if removed from view, we want to focus on next entity.
                        {- ( Just oldIndex, Just newIndex ) ->
                           if oldIndex < newIndex then
                               setFocusInIndex (oldIndex)
                           else if oldIndex > newIndex then
                               setFocusInIndex (oldIndex + 1)
                           else
                               identity
                        -}
                        ( Just oldIndex, Nothing ) ->
                            setFocusInIndex oldIndex

                        _ ->
                            identity
    in
        ( oldModel, newModel )
            |> Tuple2.mapBoth
                (getCurrentViewEntityList >> (getMaybeFocusInEntityIndex # oldModel))
            |> updateEntityListCursorFromEntityIndexTuple newModel


updateEntityListCursor oldModel newModel =
    ( oldModel, newModel )
        |> Tuple2.mapBoth
            (getCurrentViewEntityList >> (getMaybeFocusInEntityIndex # oldModel))
        |> updateEntityListCursorFromEntityIndexTuple newModel


updateEntityListCursorFromEntityIndexTuple model indexTuple =
    let
        setFocusInEntityByIndex index entityList model =
            List.clampIndex index entityList
                |> (List.getAt # entityList)
                |> Maybe.orElse (List.head entityList)
                |> maybeSetIn model focusInEntity

        setFocusInIndex index =
            setFocusInEntityByIndex
                index
                (getCurrentViewEntityList model)
    in
        model
            |> case indexTuple of
                ( Just oldIndex, Just newIndex ) ->
                    if oldIndex < newIndex then
                        setFocusInIndex (oldIndex)
                    else if oldIndex > newIndex then
                        setFocusInIndex (oldIndex + 1)
                    else
                        identity

                ( Just oldIndex, Nothing ) ->
                    setFocusInIndex oldIndex

                _ ->
                    identity


findAndUpdateAllTodos findFn action model =
    let
        updateFn =
            Todo.update action
    in
        X.Record.overT2 todoStore (Store.updateAndPersist findFn model.now updateFn) model
            |> Tuple2.swap
            |> Return.map (updateEntityListCursor model)


updateTodo : Todo.UpdateAction -> Todo.Id -> ModelReturnF msg
updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action


updateAllTodos : Todo.UpdateAction -> Document.IdSet -> ModelReturnF msg
updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model



-- combo


updateCombo : Keyboard.Combo.Msg -> ModelReturnF Msg
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)
