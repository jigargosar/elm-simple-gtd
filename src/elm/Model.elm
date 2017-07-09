module Model exposing (..)

import AppDrawer.Model
import CommonMsg
import Context
import Document exposing (Document)
import Document.Types exposing (DocId)
import Entity.Tree
import Entity.Types exposing (EntityListViewType, EntityType)
import Entity
import ExclusiveMode
import ExclusiveMode.Types exposing (ExclusiveMode(..), SyncForm)
import Firebase
import Firebase.SignIn
import Firebase.Types exposing (FCMToken, FirebaseClient, FirebaseUser)
import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Material
import Msg exposing (..)
import Todo.Notification.Types exposing (TodoReminderOverlayModel)
import Todo.Types exposing (TodoAction(..), TodoDoc, TodoStore)
import Types exposing (AppConfig, AppModel)
import ViewType exposing (ViewType(EntityListView))
import X.Keyboard as Keyboard exposing (KeyboardEvent, KeyboardState)
import X.List as List
import X.Predicate as Pred
import X.Record exposing (maybeOver, maybeOverT2, maybeSetIn, over, overReturn, overT2, set)
import Firebase.Types exposing (DeviceId)
import GroupDoc
import Keyboard.Combo exposing (combo1, combo2, combo3)
import Keyboard.Combo as Combo
import LaunchBar.Form
import Menu
import Project
import Todo.Notification.Model
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
import Todo.GroupForm
import Todo.TimeTracker
import X.Debug


onSetEntityListView =
    EntityListView >> OnSetViewType


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


type alias ModelF =
    AppModel -> AppModel


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


editMode =
    X.Record.field .editMode (\s b -> { b | editMode = s })


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


type alias Return =
    Return.Return Msg AppModel


type alias ModelReturnF =
    AppModel -> Return


type alias ReturnF =
    Return.Return Msg AppModel -> Return.Return Msg AppModel


inboxEntity =
    Entity.fromContext Context.null


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


getActiveTodoListHavingActiveContext model =
    model.todoStore |> Store.filterDocs (allPass [ Todo.isActive, isTodoContextActive model ])


getActiveTodoListHavingActiveProject model =
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


createGrouping : EntityListViewType -> AppModel -> Entity.Tree.Tree
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
            Entity.Types.ContextsView ->
                getActiveContexts model
                    |> Entity.Tree.initContextForest
                        getActiveTodoListForContextHelp

            Entity.Types.ProjectsView ->
                getActiveProjects model
                    |> Entity.Tree.initProjectForest
                        getActiveTodoListForProjectHelp

            Entity.Types.ContextView id ->
                findContextById id model
                    ?= Context.null
                    |> Entity.Tree.initContextRoot
                        getActiveTodoListForContextHelp
                        findProjectByIdHelp

            Entity.Types.ProjectView id ->
                findProjectById id model
                    ?= Project.null
                    |> Entity.Tree.initProjectRoot
                        getActiveTodoListForProjectHelp
                        findContextByIdHelp

            Entity.Types.BinView ->
                Entity.Tree.initTodoForest
                    "Bin"
                    (filterTodosAndSortByLatestModified Document.isDeleted model)

            Entity.Types.DoneView ->
                Entity.Tree.initTodoForest
                    "Done"
                    (filterTodosAndSortByLatestModified
                        (Pred.all [ Document.isNotDeleted, Todo.isDone ])
                        model
                    )

            Entity.Types.RecentView ->
                Entity.Tree.initTodoForest
                    "Recent"
                    (filterTodosAndSortByLatestModified Pred.always model)


getActiveTodoListWithReminderTime model =
    model.todoStore |> Store.filterDocs (Todo.isReminderOverdue model.now)


findTodoWithOverDueReminder model =
    model.todoStore |> Store.findBy (Todo.isReminderOverdue model.now)


setReminderOverlayToInitialView todo model =
    { model | reminderOverlay = Todo.Notification.Model.initialView todo }


showReminderOverlayForTodoId todoId =
    applyMaybeWith (findTodoById todoId)
        (setReminderOverlayToInitialView)


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


findAndSnoozeOverDueTodo : AppModel -> Maybe ( ( TodoDoc, AppModel ), Cmd Msg )
findAndSnoozeOverDueTodo model =
    let
        snooze todoId =
            updateTodo (TA_AutoSnooze model.now) todoId model
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


switchToNewUserSetupModeIfNeeded model =
    if Store.isEmpty model.todoStore then
        setEditMode createSetupExclusiveMode model
    else
        deactivateEditingMode model


createSetupExclusiveMode =
    XMSetup (Todo.NewForm.create inboxEntity "")


activateLaunchBar : Time -> ModelF
activateLaunchBar now =
    set editMode (LaunchBar.Form.create now |> XMLaunchBar)


updateLaunchBarInput now text form =
    set editMode (LaunchBar.Form.updateInput now text form |> XMLaunchBar)


onNewTodoModeWithFocusInEntityAsReference model =
    Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo |> OnStartExclusiveMode


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    set editMode (Todo.NewForm.create (model.focusInEntity) "" |> XMNewTodo) model


activateNewTodoModeWithInboxAsReference : ModelF
activateNewTodoModeWithInboxAsReference =
    set editMode (Todo.NewForm.create inboxEntity "" |> XMNewTodo)


updateNewTodoText form text =
    set editMode (Todo.NewForm.setText text form |> XMNewTodo)


startEditingReminder : TodoDoc -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> XMEditTodoReminder)


startEditingTodoProject : TodoDoc -> ModelF
startEditingTodoProject todo =
    setEditMode (Todo.GroupForm.init todo |> XMEditTodoProject)


startEditingTodoContext : TodoDoc -> ModelF
startEditingTodoContext todo =
    setEditMode (Todo.GroupForm.init todo |> XMEditTodoContext)


showMainMenu =
    setEditMode (Menu.initState |> XMMainMenu)


startEditingEntity : EntityType -> ModelF
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
        XMEditContext ecm ->
            setEditMode (ExclusiveMode.editContextSetName newName ecm) model

        XMEditProject epm ->
            setEditMode (ExclusiveMode.editProjectSetName newName epm) model

        _ ->
            model


saveCurrentForm model =
    case model.editMode of
        XMEditContext form ->
            model
                |> updateContext form.id
                    (Context.setName form.name)

        XMEditProject form ->
            model
                |> updateProject form.id
                    (Project.setName form.name)

        XMEditTodo form ->
            model
                |> updateTodo (TA_SetText form.todoText) form.id

        XMEditTodoReminder form ->
            model
                |> updateTodo (TA_SetScheduleFromMaybeTime (Todo.ReminderForm.getMaybeTime form)) form.id

        XMEditTodoContext form ->
            model |> Return.singleton

        XMEditTodoProject form ->
            model |> Return.singleton

        XMTodoMoreMenu _ ->
            model |> Return.singleton

        XMNewTodo form ->
            saveNewTodoForm form model

        XMEditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }
                |> Return.singleton

        XMLaunchBar form ->
            model |> Return.singleton

        XMMainMenu _ ->
            model |> Return.singleton

        XMNone ->
            model |> Return.singleton

        XMSignInOverlay ->
            model |> Return.singleton

        XMSetup form ->
            saveNewTodoForm form model


saveNewTodoForm form model =
    insertTodo (Todo.init model.now (form |> Todo.NewForm.getText)) model
        |> Tuple.mapFirst Document.getId
        |> uncurry
            (\todoId ->
                updateTodo
                    (case form.referenceEntity of
                        Entity.Types.TodoEntity fromTodo ->
                            (TA_CopyProjectAndContextId fromTodo)

                        Entity.Types.GroupEntity g ->
                            case g of
                                Entity.Types.ContextEntity context ->
                                    (TA_SetContext context)

                                Entity.Types.ProjectEntity project ->
                                    (TA_SetProject project)
                    )
                    todoId
                    >> Tuple.mapFirst (setFocusInEntityFromTodoId todoId)
            )


setFocusInEntityFromTodoId : DocId -> ModelF
setFocusInEntityFromTodoId todoId model =
    maybe2Tuple ( findTodoById todoId model ?|> Entity.Types.TodoEntity, Just model )
        ?|> uncurry setFocusInEntity
        ?= model


toggleDeleteEntity : EntityType -> ModelReturnF
toggleDeleteEntity entity model =
    let
        entityId =
            getEntityId entity
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


deactivateEditingMode =
    setEditMode ExclusiveMode.none


getEditMode : AppModel -> ExclusiveMode
getEditMode =
    (.editMode)


setEditMode : ExclusiveMode -> ModelF
setEditMode =
    set editMode


updateEditModeM : (AppModel -> ExclusiveMode) -> ModelF
updateEditModeM updater model =
    setEditMode (updater model) model


clearSelection =
    setSelectedEntityIdSet Set.empty


findTodoById : DocId -> AppModel -> Maybe TodoDoc
findTodoById id =
    .todoStore >> Store.findById id


findProjectById : DocId -> AppModel -> Maybe Project.Model
findProjectById id =
    .projectStore
        >> Store.findById id
        >> Maybe.orElseLazy (\_ -> ([ Project.null ] |> List.find (Document.hasId id)))


findProjectByIdIn =
    flip findProjectById


findContextById : DocId -> AppModel -> Maybe Context.Model
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


insertTodo : (DeviceId -> DocId -> TodoDoc) -> AppModel -> ( TodoDoc, AppModel )
insertTodo constructWithId =
    X.Record.overT2 todoStore (Store.insert (constructWithId))


upsertEncodedDocOnPouchDBChange : String -> E.Value -> AppModel -> Maybe ( EntityType, AppModel )
upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            maybeOverT2 todoStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromTodo

        "project-db" ->
            maybeOverT2 projectStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromProject

        "context-db" ->
            maybeOverT2 contextStore (Store.upsertOnPouchDBChange encodedEntity)
                >>? Tuple.mapFirst Entity.fromContext

        _ ->
            (\_ -> Nothing)


upsertEncodedDocOnFirebaseChange : String -> E.Value -> AppModel -> Cmd msg
upsertEncodedDocOnFirebaseChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            .todoStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "project-db" ->
            .projectStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        "context-db" ->
            .contextStore >> (Store.upsertInPouchDbOnFirebaseChange encodedEntity)

        _ ->
            (\_ -> Cmd.none)


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


toggleEntitySelection entity =
    updateSelectedEntityIdSet (toggleSetMember (getEntityId entity))


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


setProjectStore : ProjectStore -> ModelF
setProjectStore projectStore model =
    { model | projectStore = projectStore }


setProjectStoreIn =
    flip setProjectStore


setContextStore : ContextStore -> ModelF
setContextStore contextStore model =
    { model | contextStore = contextStore }


setContextStoreIn =
    flip setContextStore


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


setFocusInEntity entity =
    set focusInEntity entity


getMaybeFocusInEntityIndex entityList model =
    entityList
        |> List.findIndex (Entity.equalById model.focusInEntity)


getMaybeFocusInEntity entityList model =
    entityList
        |> List.find (Entity.equalById model.focusInEntity)
        |> Maybe.orElse (List.head entityList)


moveFocusBy : Int -> List EntityType -> ModelF
moveFocusBy =
    Entity.findEntityByOffsetIn >>> maybeOver focusInEntity



-- Document Query Helpers


getActiveProjects =
    filterProjects GroupDoc.isActive


getActiveContexts =
    filterContexts GroupDoc.isActive



-- Document Update Helpers


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


updateTodo : TodoAction -> DocId -> ModelReturnF
updateTodo action todoId =
    findAndUpdateAllTodos (Document.hasId todoId) action


updateAllTodos : TodoAction -> Document.IdSet -> ModelReturnF
updateAllTodos action idSet model =
    findAndUpdateAllTodos (Document.getId >> Set.member # idSet) action model



-- combo


updateCombo : Keyboard.Combo.Msg -> ModelReturnF
updateCombo comboMsg =
    overReturn
        keyComboModel
        (Keyboard.Combo.update comboMsg)



-- common cmds


setDomFocusToFocusInEntityCmd =
    (commonMsg.focus ".entity-list .focusable-list-item[tabindex=0]")
