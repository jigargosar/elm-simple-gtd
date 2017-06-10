module Model exposing (..)

import CommonMsg
import Context
import Date
import Date.Extra.Create
import Dict.Extra
import Document exposing (Document)
import EditMode exposing (EditMode)
import Entity exposing (Entity)
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Ext.List as List
import Ext.Predicate
import Ext.Record as Record exposing (maybeOver, maybeSetIn, over, overReturn, set)
import Firebase exposing (DeviceId)
import Keyboard.Combo
import LaunchBar.Form
import Menu
import Project
import ReminderOverlay
import Dict exposing (Dict)
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Navigation exposing (Location)
import Ext.Random as Random
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Random.Pcg as Random exposing (Seed)
import Return
import Ext.Return as Return
import Set exposing (Set)
import Store
import Time exposing (Time)
import Todo
import Todo.Form
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


type TodoMsg
    = OnTodoToggleRunning Todo.Id
    | OnTodoStopRunning
    | OnTodoTogglePaused


type Msg
    = OnCommonMsg CommonMsg.Msg
    | OnPouchDBChange String D.Value
    | OnFirebaseChange String D.Value
    | OnUserChanged Firebase.User
    | OnFCMTokenChanged Firebase.FCMToken
    | OnFirebaseConnectionChanged Bool
    | SignIn
    | SignOut
    | RemotePouchSync EditMode.SyncForm
    | TodoAction Todo.UpdateAction Todo.Id
    | ReminderOverlayAction ReminderOverlay.Action
    | OnNotificationClicked TodoNotificationEvent
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
    | DeactivateEditingMode
    | NewTodoKeyUp KeyboardEvent
    | StartEditingReminder Todo.Model
    | StartEditingContext Todo.Model
    | StartEditingProject Todo.Model
    | SaveCurrentForm
    | UpdateRemoteSyncFormUri EditMode.SyncForm String
    | OnEditTodoProjectMenuStateChanged Todo.GroupForm.Model Menu.State
    | OnEditTodoContextMenuStateChanged Todo.GroupForm.Model Menu.State
    | UpdateTodoForm Todo.Form.Model Todo.Form.Action
    | UpdateReminderForm Todo.ReminderForm.Model Todo.ReminderForm.Action
    | OnEntityListKeyDown (List Entity) KeyboardEvent
    | SwitchView ViewType
    | SetGroupByView EntityListViewType
    | ShowReminderOverlayForTodoId Todo.Id
    | OnNowChanged Time
    | OnKeyboardMsg Keyboard.Msg
    | OnGlobalKeyUp Keyboard.Key
    | OnEntityAction Entity Entity.Action
    | OnLaunchBarMsg LaunchBar.Action
    | OnLaunchBarMsgWithNow LaunchBar.Action Time
    | OnTodoMsg TodoMsg
    | OnTodoMsgWithTime TodoMsg Time
    | OnKeyCombo Keyboard.Combo.Msg


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ Keyboard.Combo.combo2 ( Keyboard.Combo.control, Keyboard.Combo.s ) commonMsg.noOp
    , Keyboard.Combo.combo2 ( Keyboard.Combo.control, Keyboard.Combo.a ) commonMsg.noOp
    , Keyboard.Combo.combo3 ( Keyboard.Combo.control, Keyboard.Combo.alt, Keyboard.Combo.e ) commonMsg.noOp
    ]


onTodoToggleRunning =
    OnTodoToggleRunning >> OnTodoMsg


onTodoStopRunning =
    OnTodoStopRunning |> OnTodoMsg


onTodoTogglePaused =
    OnTodoTogglePaused |> OnTodoMsg


commonMsg : CommonMsg.Helper Msg
commonMsg =
    CommonMsg.createHelper OnCommonMsg


type alias EntityListViewType =
    Entity.ListViewType


type ViewType
    = EntityListView EntityListViewType
    | DoneView
    | BinView
    | SyncView


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editMode : EditMode
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
    , keyComboState : Keyboard.Combo.Model Msg
    }


type alias Layout =
    { narrow : Bool
    , forceNarrow : Bool
    }


type alias ModelF =
    Model -> Model


type alias Flags =
    { now : Time
    , encodedTodoList : List Todo.Encoded
    , encodedProjectList : List Project.Encoded
    , encodedContextList : List Context.Encoded
    , pouchDBRemoteSyncURI : String
    , developmentMode : Bool
    , appVersion : String
    , deviceId : String
    }


type alias TodoNotification =
    { title : String
    , tag : String
    , data : TodoNotificationData
    }


type alias TodoNotificationData =
    { id : String }


type alias TodoNotificationEvent =
    { action : String
    , data : TodoNotificationData
    }



-- Model Lens


contextStore =
    Record.init .contextStore (\s b -> { b | contextStore = s })


projectStore =
    Record.init .projectStore (\s b -> { b | projectStore = s })


todoStore =
    Record.init .todoStore (\s b -> { b | todoStore = s })


keyboardState =
    Record.init .keyboardState (\s b -> { b | keyboardState = s })


now =
    Record.init .now (\s b -> { b | now = s })


firebaseClient =
    Record.init .firebaseClient (\s b -> { b | firebaseClient = s })


editMode =
    Record.init .editMode (\s b -> { b | editMode = s })


user =
    Record.init .user (\s b -> { b | user = s })


focusInEntity =
    Record.init .focusInEntity (\s b -> { b | focusInEntity = s })


timeTracker =
    Record.init .timeTracker (\s b -> { b | timeTracker = s })


keyComboState =
    Record.init .keyComboState (\s b -> { b | keyComboState = s })


init : Flags -> Model
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

        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = EditMode.none
            , mainViewType = EntityListView Entity.defaultListView
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
            , keyComboState =
                Keyboard.Combo.init
                    { toMsg = OnKeyCombo
                    , combos = keyboardCombos
                    }
            }
    in
        model


inboxEntity =
    Entity.ContextEntity Context.null


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


filterTodos pred model =
    Store.filter pred model.todoStore
        |> List.sortBy (Todo.getCreatedAt >> negate)


filterContexts pred model =
    Store.filter pred model.contextStore
        |> List.append (Context.filterNull pred)
        |> Context.sort


filterProjects pred model =
    Store.filter pred model.projectStore
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


createGrouping : Entity.ListViewType -> Model -> Entity.Grouping
createGrouping viewType model =
    let
        deletedFilter =
            if model.showDeleted then
                Document.isDeleted
            else
                Document.isDeleted >> not

        todoFilter =
            if model.showDeleted then
                Document.isDeleted
            else
                Ext.Predicate.all [ Todo.isNotDeleted, Todo.isNotDone ]

        filterTodosForContext context =
            filterTodos
                (Ext.Predicate.all
                    [ todoFilter
                    , Todo.contextFilter context
                    ]
                )
                model

        filterTodosForProject project =
            filterTodos
                (Ext.Predicate.all
                    [ todoFilter
                    , Todo.projectFilter project
                    ]
                )
                model

        findProjectByIdHelp id =
            findProjectById id model

        findContextByIdHelp id =
            findContextById id model
    in
        case viewType of
            Entity.ContextsView ->
                filterCurrentContexts model
                    |> Entity.createGroupingForContexts filterTodosForContext

            Entity.ProjectsView ->
                filterCurrentProjects model
                    |> Entity.createGroupingForProjects filterTodosForProject

            Entity.ContextView id ->
                findContextById id model
                    ?= Context.null
                    |> Entity.createGroupingForContext filterTodosForContext findProjectByIdHelp

            Entity.ProjectView id ->
                findProjectById id model
                    ?= Project.null
                    |> Entity.createGroupingForProject filterTodosForProject findContextByIdHelp


getActiveTodoList =
    .todoStore >> Store.reject (anyPass [ Todo.isDeleted, Todo.isDone ])


getActiveTodoListWithReminderTime model =
    model.todoStore |> Store.filter (Todo.isReminderOverdue model.now)


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


getActiveTodoListGroupedBy fn =
    getActiveTodoList >> Dict.Extra.groupBy (fn)


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (setProjectStore # model)
        |> (\( project, model ) ->
                model
                    |> switchToProjectView project
                    |> startEditingEntity (Entity.ProjectEntity project)
           )


createAndEditNewContext model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (setContextStore # model)
        |> (\( context, model ) ->
                model
                    |> switchToContextView context
                    |> startEditingEntity (Entity.ContextEntity context)
           )


isShowDetailsKeyPressed =
    .keyboardState >> Keyboard.isAltDown >> not


activateLaunchBar : Time -> ModelF
activateLaunchBar now =
    set editMode (LaunchBar.Form.create now |> EditMode.LaunchBar)


updateLaunchBarInput now text form =
    set editMode (LaunchBar.Form.updateInput now text form |> EditMode.LaunchBar)


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    set editMode (Todo.NewForm.create (model.focusInEntity) "" |> EditMode.NewTodo) model


activateNewTodoModeWithInboxAsReference : ModelF
activateNewTodoModeWithInboxAsReference =
    set editMode (Todo.NewForm.create inboxEntity "" |> EditMode.NewTodo)


updateNewTodoText form text =
    set editMode (Todo.NewForm.setText text form |> EditMode.NewTodo)


startEditingReminder : Todo.Model -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> EditMode.EditTodoReminder)


startEditingTodoProject : Todo.Model -> ModelF
startEditingTodoProject todo =
    setEditMode (Todo.GroupForm.init todo |> EditMode.EditTodoProject)


startEditingTodoContext : Todo.Model -> ModelF
startEditingTodoContext todo =
    setEditMode (Todo.GroupForm.init todo |> EditMode.EditTodoContext)


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    setEditMode (createEntityEditForm entity model) model


switchToEntityListViewFromEntity entity model =
    let
        maybeEntityListViewType =
            maybeGetCurrentEntityListViewType model
    in
        entity |> Entity.getGotoEntityViewType maybeEntityListViewType |> (setEntityListViewType # model)


updateEditModeNameChanged newName entity model =
    case model.editMode of
        EditMode.EditContext ecm ->
            setEditMode (EditMode.editContextSetName newName ecm) model

        EditMode.EditProject epm ->
            setEditMode (EditMode.editProjectSetName newName epm) model

        _ ->
            model


saveCurrentForm model =
    case model.editMode of
        EditMode.EditContext form ->
            model
                |> updateContext form.id
                    (Context.setName form.name)

        EditMode.EditProject form ->
            model
                |> updateProject form.id
                    (Project.setName form.name)

        EditMode.EditTodo form ->
            model
                |> updateTodo (Todo.SetText form.todoText) form.id

        EditMode.EditTodoReminder form ->
            model
                |> updateTodo (Todo.SetScheduleFromMaybeTime (Todo.ReminderForm.getMaybeTime form)) form.id

        EditMode.EditTodoContext form ->
            model
                |> Return.singleton

        EditMode.EditTodoProject form ->
            model
                |> Return.singleton

        EditMode.NewTodo form ->
            insertTodo (Todo.init model.now (form |> Todo.NewForm.getText)) model
                |> Tuple.mapFirst Document.getId
                |> uncurry
                    (\todoId ->
                        updateTodo
                            (case form.referenceEntity of
                                Entity.TodoEntity fromTodo ->
                                    (Todo.CopyProjectAndContextId fromTodo)

                                Entity.ContextEntity context ->
                                    (Todo.SetContext context)

                                Entity.ProjectEntity project ->
                                    (Todo.SetProject project)
                            )
                            todoId
                            >> Tuple.mapFirst (setFocusInEntityFromTodoId todoId)
                    )

        EditMode.EditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        EditMode.LaunchBar form ->
            model
                |> Return.singleton

        EditMode.None ->
            model
                |> Return.singleton


setFocusInEntityFromTodoId : Todo.Id -> ModelF
setFocusInEntityFromTodoId todoId model =
    maybe2Tuple ( findTodoById todoId model ?|> Entity.TodoEntity, Just model )
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
                Entity.ContextEntity context ->
                    updateContext entityId Document.toggleDeleted

                Entity.ProjectEntity project ->
                    updateProject entityId Document.toggleDeleted

                Entity.TodoEntity todo ->
                    updateTodo (Todo.ToggleDeleted) entityId


getMaybeEditTodoReminderForm model =
    case model.editMode of
        EditMode.EditTodoReminder form ->
            Just form

        _ ->
            Nothing


getRemoteSyncForm model =
    let
        maybeForm =
            case model.editMode of
                EditMode.EditSyncSettings form ->
                    Just form

                _ ->
                    Nothing
    in
        maybeForm ?= createRemoteSyncForm model


createRemoteSyncForm : Model -> EditMode.SyncForm
createRemoteSyncForm model =
    { uri = model.pouchDBRemoteSyncURI }


createEntityEditForm : Entity -> Model -> EditMode
createEntityEditForm entity model =
    case entity of
        Entity.ContextEntity context ->
            EditMode.editContextMode context

        Entity.ProjectEntity project ->
            EditMode.editProjectMode project

        Entity.TodoEntity todo ->
            Todo.Form.create todo |> EditMode.EditTodo


deactivateEditingMode =
    setEditMode EditMode.none


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


setEditMode : EditMode -> ModelF
setEditMode editMode =
    (\model -> { model | editMode = editMode })


updateEditModeM : (Model -> EditMode) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


clearSelection =
    setSelectedEntityIdSet Set.empty


getTodoListForCurrentView model =
    let
        filter =
            model |> getTodoListFilterForCurrentView

        allTodos =
            model |> getTodoStore >> Store.asList

        sortFunction =
            model
                |> getCurrentTodoListSortByFunction
    in
        allTodos
            |> List.filter filter
            |> List.sortBy sortFunction
            |> List.take 50


getTodoListFilterForCurrentView model =
    let
        default =
            Todo.toAllPassPredicate [ Todo.isDone >> not, Todo.isDeleted >> equals model.showDeleted ]
    in
        case getMainViewType model of
            BinView ->
                Todo.binFilter

            DoneView ->
                Todo.doneFilter

            EntityListView viewType ->
                case viewType of
                    Entity.ContextsView ->
                        default

                    Entity.ContextView id ->
                        Todo.toAllPassPredicate [ Todo.getContextId >> equals id, default ]

                    Entity.ProjectsView ->
                        default

                    Entity.ProjectView id ->
                        Todo.toAllPassPredicate [ Todo.getProjectId >> equals id, default ]

            _ ->
                always (True)


getCurrentTodoListSortByFunction model =
    case getMainViewType model of
        BinView ->
            Todo.getModifiedAt >> negate

        DoneView ->
            Todo.getModifiedAt >> negate

        _ ->
            Todo.getModifiedAt >> negate


findTodoById : Document.Id -> Model -> Maybe Todo.Model
findTodoById id =
    getTodoStore >> Store.findById id


findProjectById : Document.Id -> Model -> Maybe Project.Model
findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Project.null ] |> List.find (Document.hasId id)))


findContextById : Document.Id -> Model -> Maybe Context.Model
findContextById id =
    .contextStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Context.null ] |> List.find (Document.hasId id)))


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
    Record.overT2 todoStore (Store.insert (constructWithId))


setTodoStoreFromTuple tuple model =
    tuple |> Tuple.mapSecond (setTodoStore # model)


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            over todoStore (Store.upsertOnPouchDBChange encodedEntity)

        "project-db" ->
            over projectStore (Store.upsertOnPouchDBChange encodedEntity)

        "context-db" ->
            over contextStore (Store.upsertOnPouchDBChange encodedEntity)

        _ ->
            identity


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
            createGrouping viewType model |> Entity.flattenGrouping

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
    filterProjects Document.isNotDeleted


getActiveContexts =
    filterContexts Document.isNotDeleted


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
    Record.overT2 store (Store.updateAll idSet model.now updateFn) model
        |> apply2 ( Tuple.second, (\changes -> Cmd.none) )
        |> Return.map (updateEntityListCursor model)


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
                -- note: currently we are focusing next entity only if current entity is removed from the view.
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


findAndUpdateAllTodos findFn action model =
    let
        todoChangesToCmd ( changes, model ) =
            case getMaybeUserId model of
                Nothing ->
                    Cmd.none

                Just uid ->
                    changes
                        .|> getNotificationCmdFromTodoChange uid
                        |> Cmd.batch

        updateFn =
            Todo.update action
    in
        Record.overT2 todoStore (Store.findAndUpdateAll findFn model.now updateFn) model
            |> apply2 ( Tuple.second, todoChangesToCmd )
            |> Return.map (updateEntityListCursor model)


updateTodo : Todo.UpdateAction -> Todo.Id -> ModelReturnF msg
updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action


updateAllTodos : Todo.UpdateAction -> Document.IdSet -> ModelReturnF msg
updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model


getNotificationCmdFromTodoChange uid (( old, new ) as change) =
    if Todo.hasReminderChanged change then
        let
            todoId =
                Document.getId new

            maybeTime =
                Todo.getMaybeReminderTime new
        in
            Firebase.scheduledReminderNotificationCmd maybeTime uid todoId
    else
        Cmd.none



-- todo time tracking


toggleTodoTimer todoId now =
    over timeTracker (Todo.TimeTracker.toggleStartStop todoId now)


toggleTodoPause now =
    over timeTracker (Todo.TimeTracker.togglePause now)


stopRunningTodo =
    Record.set timeTracker Todo.TimeTracker.none


gotoRunningTodo model =
    Todo.TimeTracker.getMaybeTodoId model.timeTracker
        ?|> gotoTodoWithIdIn model
        ?= model


gotoTodoWithIdIn =
    flip gotoTodoWithId


gotoTodoWithId todoId model =
    let
        maybeTodoEntity =
            getCurrentViewEntityList model
                |> List.find
                    (\entity ->
                        case entity of
                            Entity.TodoEntity doc ->
                                Document.hasId todoId doc

                            _ ->
                                False
                    )
    in
        maybeTodoEntity
            |> Maybe.unpack
                (\_ ->
                    model |> setFocusInEntityFromTodoId todoId |> switchToContextsView
                )
                (setFocusInEntity # model)



-- combo


updateCombo : Keyboard.Combo.Msg -> ModelReturnF Msg
updateCombo comboMsg =
    overReturn
        keyComboState
        (Keyboard.Combo.update comboMsg)
