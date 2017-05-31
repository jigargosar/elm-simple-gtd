module Model exposing (..)

import Context
import Date
import Date.Extra.Create
import Dict.Extra
import Document exposing (Document)
import EditMode exposing (EditMode)
import Entity exposing (Entity)
import Ext.Keyboard as Keyboard
import Ext.List as List
import Firebase exposing (DeviceId)
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
    , focusedEntityInfo : EntityFocus
    , selectedEntityIdSet : Set Document.Id
    , layout : Layout
    , maybeFocusedEntity : Maybe Entity
    , appVersion : String
    , deviceId : String
    , firebaseClient : Firebase.Client
    , focusInEntity : Entity.Entity
    }


type alias Layout =
    { narrow : Bool
    , forceNarrow : Bool
    }


type alias EntityFocus =
    { id : Document.Id }


type alias ModelF =
    Model -> Model


type GroupEntityType
    = ProjectGroup
    | ContextGroup


type GroupEntity
    = ProjectGroupEntity Project.Model
    | ContextGroupEntity Context.Model


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


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


contextStore =
    { get = .contextStore, set = (\s b -> { b | contextStore = s }) }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


todoStore =
    { get = .todoStore, set = (\s b -> { b | todoStore = s }) }


todoStoreT2 =
    { get = .todoStore, set = (\( x, s ) b -> ( x, { b | todoStore = s } )) }


keyboardState =
    { get = .keyboardState, set = (\s b -> { b | keyboardState = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }


firebaseClient =
    { get = .firebaseClient, set = (\s b -> { b | firebaseClient = s }) }


editMode =
    { get = .editMode, set = (\s b -> { b | editMode = s }) }


user =
    { get = .user, set = (\s b -> { b | user = s }) }


focusInEntity =
    { get = .focusInEntity, set = (\s b -> { b | focusInEntity = s }) }


update lens smallF big =
    setIn big lens (smallF (lens.get big))


setIn big lens small =
    lens.set small big


updateMaybe lens smallMaybeF big =
    let
        maybeSmallT =
            smallMaybeF (lens.get big)

        maybeBigT =
            maybeSmallT ?|> setIn big lens
    in
        maybeBigT


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
            , focusedEntityInfo = { id = "" }
            , selectedEntityIdSet = Set.empty
            , layout = { narrow = False, forceNarrow = False }
            , maybeFocusedEntity = Nothing
            , appVersion = flags.appVersion
            , deviceId = flags.deviceId
            , focusInEntity = inboxEntity
            , firebaseClient = firebaseClient
            }
    in
        model


inboxEntity =
    Entity.ContextEntity Context.null


getMaybeUserProfile =
    user.get >> Firebase.getMaybeUserProfile


getMaybeUserId =
    user.get >> Firebase.getMaybeUserId


setUser =
    user.set


setFCMToken fcmToken model =
    { model | fcmToken = fcmToken }
        |> update firebaseClient (Firebase.updateToken fcmToken)


updateFirebaseConnection connected =
    update firebaseClient (Firebase.updateConnection connected)


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


getEntityStore entityType =
    case entityType of
        ProjectGroup ->
            .projectStore

        ContextGroup ->
            .contextStore


getMaybeEditModelForEntityType : GroupEntityType -> Model -> Maybe EditMode.EntityForm
getMaybeEditModelForEntityType entityType model =
    case ( entityType, model.editMode ) of
        ( ProjectGroup, EditMode.EditProject editModel ) ->
            Just editModel

        ( ContextGroup, EditMode.EditContext editModel ) ->
            Just editModel

        _ ->
            Nothing


getEntityList =
    getEntityStore >>> Store.asList


getDeletedEntityList =
    getEntityStore >>> Store.filter Document.isDeleted


getActiveEntityList =
    getEntityStore >>> Store.reject Document.isDeleted


getFilteredContextList model =
    if model.showDeleted then
        getDeletedEntityList ContextGroup model
    else
        Context.null :: getActiveEntityList ContextGroup model


getFilteredProjectList model =
    if model.showDeleted then
        getDeletedEntityList ProjectGroup model
    else
        Project.null :: getActiveEntityList ProjectGroup model


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


findAndSnoozeOverDueTodo : Model -> Maybe ( Todo.Model, Model )
findAndSnoozeOverDueTodo model =
    findAndUpdateTodoT2
        (Todo.isReminderOverdue model.now)
        (Todo.SnoozeTill (model.now + (Time.minute * 15)))
        model


getActiveTodoListGroupedBy fn =
    getActiveTodoList >> Dict.Extra.groupBy (fn)


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (setProjectStore # model)
        |> (\( project, model ) -> startEditingEntity (Entity.ProjectEntity project) model)


createAndEditNewContext model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (setContextStore # model)
        |> (\( context, model ) -> startEditingEntity (Entity.ContextEntity context) model)


isShowDetailsKeyPressed =
    keyboardState.get >> Keyboard.isAltDown >> not



--
--
--update2 lens l2 smallF big =
--    lens.set (smallF (l2.get big) (lens.get big)) big
--


activateNewTodoModeWithFocusInEntityAsReference : ModelF
activateNewTodoModeWithFocusInEntityAsReference model =
    editMode.set (Todo.NewForm.create (focusInEntity.get model) "" |> EditMode.NewTodo) model


activateNewTodoModeWithInboxAsReference : ModelF
activateNewTodoModeWithInboxAsReference =
    editMode.set (Todo.NewForm.create inboxEntity "" |> EditMode.NewTodo)


updateNewTodoText form text =
    editMode.set (Todo.NewForm.setText text form |> EditMode.NewTodo)


startEditingReminder : Todo.Model -> ModelF
startEditingReminder todo =
    updateEditModeM (.now >> Todo.ReminderForm.create todo >> EditMode.EditTodoReminder)


startEditingContext : Todo.Model -> ModelF
startEditingContext todo =
    setEditMode (EditMode.EditTodoContext todo)


startEditingProject : Todo.Model -> ModelF
startEditingProject todo =
    setEditMode (EditMode.EditTodoProject todo)


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    setEditMode (createEntityEditForm entity model) model


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
                |> updateDoc form.id
                    (Context.setName form.name)
                    contextStore
                |> Return.singleton

        EditMode.EditProject form ->
            model
                |> updateDoc form.id
                    (Project.setName form.name)
                    projectStore
                |> Return.singleton

        EditMode.EditTodo form ->
            model
                |> updateTodo (Todo.SetText form.todoText) form.id

        EditMode.EditTodoReminder form ->
            model
                |> updateTodo (Todo.SetTime (Todo.ReminderForm.getMaybeTime form)) form.id

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
                    updateDoc entityId
                        (Document.toggleDeleted)
                        contextStore
                        >> Return.singleton

                Entity.ProjectEntity project ->
                    updateDoc entityId
                        (Document.toggleDeleted)
                        projectStore
                        >> Return.singleton

                Entity.TodoEntity todo ->
                    updateTodo Todo.ToggleDeleted entityId


getMaybeEditTodoReminderForm model =
    case model.editMode of
        EditMode.EditTodoReminder form ->
            Just form

        _ ->
            Nothing


getMaybeEditTodoContextForm model =
    case model.editMode of
        EditMode.EditTodoContext form ->
            Just form

        _ ->
            Nothing


getMaybeEditTodoProjectForm model =
    case model.editMode of
        EditMode.EditTodoProject form ->
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



--setTodoContextOrProjectBasedOnCurrentView todoId model =
--    let
--        maybeTodoUpdateAction =
--            case model.mainViewType of
--                EntityListView viewType ->
--                    case viewType of
--                        Entity.ContextView id ->
--                            model.contextStore |> Store.findById id >>? Todo.SetContext
--
--                        Entity.ProjectView id ->
--                            model.projectStore |> Store.findById id >>? Todo.SetProject
--
--                        _ ->
--                            Nothing
--
--                _ ->
--                    Nothing
--
--        maybeModel =
--            maybeTodoUpdateAction
--                ?|> (updateTodo # todoId # model)
--    in
--        maybeModel ?= model |> setFocusInEntityWithId todoId


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
            Todo.getDeletedAt >> negate

        DoneView ->
            Todo.getModifiedAt >> negate

        _ ->
            Todo.getModifiedAt >> negate


findTodoById : Document.Id -> Model -> Maybe Todo.Model
findTodoById id =
    getTodoStore >> Store.findById id


findProjectById : Document.Id -> Model -> Maybe Project.Model
findProjectById id =
    .projectStore >> Store.findById id


findContextById : Document.Id -> Model -> Maybe Context.Model
findContextById id =
    .contextStore >> Store.findById id


type alias TodoContextViewModel =
    { name : String, todoList : List Todo.Model, count : Int, isEmpty : Bool }


groupByTodoContextViewModel : Model -> List TodoContextViewModel
groupByTodoContextViewModel =
    getTodoStore
        >> Store.asList
        >> Todo.rejectAnyPass [ Todo.isDeleted, Todo.isDone ]
        --        >> Dict.Extra.groupBy (Todo.getTodoContext >> toString)
        >> Dict.Extra.groupBy (\_ -> "Inbox")
        >> (\dict ->
                --                Todo.getAllTodoContexts
                [ "Inbox" ]
                    .|> (apply2
                            ( identity
                            , (Dict.get # dict >> Maybe.withDefault [])
                            )
                            >> (\( name, list ) ->
                                    list
                                        |> apply3 ( identity, List.length, List.isEmpty )
                                        >> uncurry3 (TodoContextViewModel name)
                               )
                        )
           )


updateTodoAndMaybeAlsoSelected action todoId model =
    let
        idSet =
            if model.selectedEntityIdSet |> Set.member todoId then
                model.selectedEntityIdSet
            else
                Set.singleton todoId

        _ =
            getFocusInEntityIndex
    in
        model |> updateAllTodos action idSet


insertTodo : (DeviceId -> Document.Id -> Todo.Model) -> Model -> ( Todo.Model, Model )
insertTodo constructWithId =
    update todoStoreT2 (Store.insert (constructWithId))


setTodoStoreFromTuple tuple model =
    tuple |> Tuple.mapSecond (setTodoStore # model)


upsertEncodedDocOnPouchDBChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            update todoStore (Store.upsertOnPouchDBChange encodedEntity)

        "project-db" ->
            update projectStore (Store.upsertOnPouchDBChange encodedEntity)

        "context-db" ->
            update contextStore (Store.upsertOnPouchDBChange encodedEntity)

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


switchView : ViewType -> ModelF
switchView mainViewType model =
    { model | mainViewType = mainViewType }
        |> clearSelection


setEntityListViewType =
    EntityListView >> switchView


getEntityId entity =
    case entity of
        Entity.TodoEntity doc ->
            Document.getId doc

        Entity.ProjectEntity doc ->
            Document.getId doc

        Entity.ContextEntity doc ->
            Document.getId doc


getCurrentViewEntityList model =
    case model.mainViewType of
        EntityListView viewType ->
            createEntityListFromEntityListViewType viewType model

        _ ->
            []


getContextListForCurrentViewFromTodoList todoList model =
    let
        contextIdSet =
            todoList
                .|> Todo.getContextId
                |> Set.fromList

        includeNull =
            Set.member "" contextIdSet

        nullContextAsList =
            if model.showDeleted || not includeNull then
                []
            else
                [ Context.null ]
    in
        contextIdSet
            |> Store.findAllByIdSetIn model.contextStore
            |> List.append nullContextAsList


getProjectListForCurrentViewFromTodoList todoList model =
    let
        projectIdSet =
            todoList
                .|> Todo.getProjectId
                |> Set.fromList

        includeNull =
            Set.member "" projectIdSet

        nullProjectAsList =
            if model.showDeleted || not includeNull then
                []
            else
                [ Project.null ]
    in
        projectIdSet
            |> Store.findAllByIdSetIn model.projectStore
            |> List.append nullProjectAsList


createEntityListFromEntityListViewType viewType model =
    let
        todoList =
            getTodoListForCurrentView model
    in
        case viewType of
            Entity.ContextsView ->
                let
                    nullEntity =
                        (Entity.ContextEntity Context.null)

                    addDefaultIfMissing =
                        when (List.notMember nullEntity)
                            ((::) nullEntity)
                in
                    getContextsViewEntityList todoList False model
                        |> addDefaultIfMissing

            Entity.ProjectsView ->
                let
                    nullEntity =
                        (Entity.ProjectEntity Project.null)

                    addDefaultIfMissing =
                        when (List.notMember nullEntity)
                            ((::) nullEntity)
                in
                    getProjectsViewEntityList todoList False model
                        |> addDefaultIfMissing

            Entity.ContextView id ->
                let
                    addDefaultIfEmpty list =
                        if List.isEmpty list then
                            findContextById id model
                                ?= Context.null
                                |> Entity.ContextEntity
                                >> List.singleton
                        else
                            list
                in
                    getContextsViewEntityList todoList True model
                        |> addDefaultIfEmpty

            Entity.ProjectView id ->
                let
                    addDefaultIfEmpty list =
                        if List.isEmpty list then
                            findProjectById id model
                                ?= Project.null
                                |> Entity.ProjectEntity
                                >> List.singleton
                        else
                            list
                in
                    getProjectsViewEntityList todoList True model
                        |> addDefaultIfEmpty


getContextsViewEntityList todoList enableSubgroup model =
    let
        todoListByContextId =
            todoList |> Dict.Extra.groupBy Todo.getContextId

        contextList =
            getContextListForCurrentViewFromTodoList todoList model

        todoEntitiesForContext context =
            todoListByContextId
                |> Dict.get (Document.getId context)
                ?= []
                .|> Entity.TodoEntity

        subGroupEntitiesForContext context =
            todoListByContextId
                |> Dict.get (Document.getId context)
                ?= []
                |> (\todoList -> getProjectsViewEntityList todoList False model)

        entitiesForContext =
            if enableSubgroup then
                subGroupEntitiesForContext
            else
                todoEntitiesForContext
    in
        contextList
            |> List.concatMap
                (\context ->
                    (Entity.ContextEntity context) :: (entitiesForContext context)
                )


getProjectsViewEntityList todoList enableSubgroup model =
    let
        todoListByProjectId =
            todoList |> Dict.Extra.groupBy Todo.getProjectId

        projectList =
            getProjectListForCurrentViewFromTodoList todoList model

        todoEntitiesForProject project =
            todoListByProjectId
                |> Dict.get (Document.getId project)
                ?= []
                .|> Entity.TodoEntity

        subGroupEntitiesForProject project =
            todoListByProjectId
                |> Dict.get (Document.getId project)
                ?= []
                |> (\todoList -> getContextsViewEntityList todoList False model)

        entitiesForProject =
            if enableSubgroup then
                subGroupEntitiesForProject
            else
                todoEntitiesForProject
    in
        projectList
            |> List.concatMap
                (\project ->
                    (Entity.ProjectEntity project) :: (entitiesForProject project)
                )


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


setFocusInEntityByIndex entityList index model =
    let
        focusedEntityId =
            List.clampIndex index entityList
                |> (List.getAt # entityList)
                ?|> getEntityId
                ?= ""

        focusedEntityInfo =
            { id = focusedEntityId }
    in
        { model | focusedEntityInfo = focusedEntityInfo }


setFocusInEntityWithId id model =
    let
        focusedEntityInfo =
            model.focusedEntityInfo
    in
        { model | focusedEntityInfo = { focusedEntityInfo | id = id } }


setFocusInEntity entity =
    setFocusInEntityWithId (getEntityId entity)
        >> focusInEntity.set entity


setMaybeFocusedEntity maybeEntity model =
    { model | maybeFocusedEntity = maybeEntity }


getFocusInEntityId model =
    model.focusedEntityInfo.id


getFocusInEntityIndex entityList model =
    getMaybeFocusInEntityIndex entityList model
        ?= 0


getMaybeFocusInEntityIndex entityList model =
    entityList
        |> List.findIndex (getEntityId >> equals model.focusedEntityInfo.id)


focusPrevEntity : List Entity -> ModelF
focusPrevEntity entityList model =
    getFocusInEntityIndex entityList model
        |> andThenSubtract 1
        |> (setFocusInEntityByIndex entityList # model)


focusNextEntity : List Entity -> ModelF
focusNextEntity entityList model =
    getFocusInEntityIndex entityList model
        |> add 1
        |> (setFocusInEntityByIndex entityList # model)



-- Document Query Helpers


getActiveProjects =
    (.projectStore) >> Store.reject Document.isDeleted >> (::) Project.null


getActiveContexts =
    (.contextStore) >> Store.reject Document.isDeleted >> (::) Context.null


getContextsAsIdDict =
    (.contextStore) >> Store.asIdDict


getProjectsAsIdDict =
    (.projectStore) >> Store.asIdDict



-- Document Update Helpers


findAndUpdateDocT :
    (Document x -> Bool)
    -> (Document x -> Document x)
    ->
        { c
            | get : Model -> Store.Store x
            , set : ( Document x, Store.Store x ) -> Model -> ( Document x, Model )
        }
    -> Model
    -> Maybe ( Document x, Model )
findAndUpdateDocT docFindFn docUpdateFn store model =
    let
        updateMaybeF =
            Store.findAndUpdateT
                docFindFn
                model.now
                docUpdateFn
    in
        updateMaybe store updateMaybeF model


updateDoc id =
    updateAllDocs (Set.singleton id)


updateEntityListCursor oldModel newModel =
    ( oldModel, newModel )
        |> Tuple2.mapBoth
            (getCurrentViewEntityList >> (getMaybeFocusInEntityIndex # oldModel))
        |> updateEntityListCursorFromEntityIndexTuple newModel


updateEntityListCursorFromEntityIndexTuple model indexTuple =
    let
        setFocusInIndex index =
            setFocusInEntityByIndex
                (getCurrentViewEntityList model)
                index
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


updateAllDocs idSet updateFn store model =
    let
        storeF =
            Store.updateAll idSet model.now updateFn
    in
        update store storeF model
            |> updateEntityListCursor model


findAndUpdateTodoT2 findFn action model =
    findAndUpdateDocT findFn (todoUpdateF action model) todoStoreT2 model



{--> Maybe ( Todo.Model, Todo.Model, Todo.Store )-}


type alias Return msg =
    Return.Return msg Model


type alias ModelReturnF msg =
    Model -> Return msg


updateTodo : Todo.UpdateAction -> Todo.Id -> ModelReturnF msg
updateTodo action todoId model =
    let
        todoChangesToCmd ( changes, model ) =
            case getMaybeUserId model of
                Nothing ->
                    Cmd.none

                Just uid ->
                    changes
                        .|> getNotificationCmdFromTodoChange uid
                        |> Cmd.batch
    in
        update todoStoreT2 (Todo.Store.update action model.now todoId) model
            |> apply2 ( Tuple.second, todoChangesToCmd )


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


updateAllTodos action todoIdSet model =
    updateAllDocs todoIdSet
        (todoUpdateF action model)
        todoStore
        model


todoUpdateF action model =
    Todo.update [ action ] model.now
