module Model exposing (..)

import Context
import Date
import Date.Extra.Create
import Dict.Extra
import Document exposing (Document)
import EditMode exposing (EditForm)
import Ext.Keyboard as Keyboard
import Ext.List as List
import Firebase
import Model.Internal exposing (..)
import Msg exposing (Return)
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
import Set
import Store
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.NewForm
import Todo.ReminderForm
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import Tuple2
import Types exposing (..)


init : Flags -> Model
init flags =
    let
        { now, encodedTodoList, encodedProjectList, encodedContextList, pouchDBRemoteSyncURI } =
            flags

        storeGenerator =
            Random.map3 (,,)
                (Todo.storeGenerator encodedTodoList)
                (Project.storeGenerator encodedProjectList)
                (Context.storeGenerator encodedContextList)

        ( ( todoStore, projectStore, contextStore ), seed ) =
            Random.step storeGenerator (Random.seedFromTime now)

        model =
            { now = now
            , todoStore = todoStore
            , projectStore = projectStore
            , contextStore = contextStore
            , editMode = EditMode.none
            , mainViewType = EntityListView GroupByContextView
            , keyboardState = Keyboard.init
            , showDeleted = False
            , reminderOverlay = ReminderOverlay.none
            , pouchDBRemoteSyncURI = pouchDBRemoteSyncURI
            , appDrawerForceNarrow = False
            , user = Firebase.NotLoggedIn
            , fcmToken = Nothing
            , firebaseAppAttributes = flags.firebaseAppAttributes
            , developmentMode = flags.developmentMode
            , focusedEntityInfo = { index = 0, id = "" }
            , selectedEntityIdSet = Set.empty
            }
    in
        model


getMaybeUserProfile =
    .user >> Firebase.getMaybeUserProfile


setUser user model =
    { model | user = user }


setFCMToken fcmToken model =
    { model | fcmToken = fcmToken }


toggleForceNarrow model =
    { model | appDrawerForceNarrow = not model.appDrawerForceNarrow }


findProjectByName name =
    getProjectStore >> Project.findByName name


findContextByName name =
    .contextStore >> Context.findByName name


getContextByIdDict =
    (.contextStore) >> Store.byIdDict


getActiveProjects =
    (.projectStore) >> Store.reject Document.isDeleted >> (::) Project.null


getActiveContexts =
    (.contextStore) >> Store.reject Document.isDeleted >> (::) Context.null


getProjectByIdDict =
    (.projectStore) >> Store.byIdDict


getEncodedContextNames =
    .contextStore >> Context.getEncodedNames


getMaybeProjectNameOfTodo : Todo.Model -> Model -> Maybe Project.Name
getMaybeProjectNameOfTodo todo model =
    Todo.getProjectId todo |> Project.findNameById # (getProjectStore model)


getContextNameOfTodo : Todo.Model -> Model -> Maybe Context.Name
getContextNameOfTodo todo model =
    Todo.getContextId todo |> Context.findNameById # (model.contextStore)


insertProjectIfNotExist : Project.Name -> ModelF
insertProjectIfNotExist projectName =
    apply2With ( getNow, getProjectStore )
        (Project.insertIfNotExistByName projectName >>> setProjectStore)


insertContextIfNotExist : Context.Name -> ModelF
insertContextIfNotExist name =
    apply2With ( getNow, .contextStore )
        (Context.insertIfNotExistByName name
            >>> (\contextStore model -> { model | contextStore = contextStore })
        )


getEntityStore entityType =
    case entityType of
        GroupByProject ->
            .projectStore

        GroupByContext ->
            .contextStore


getMaybeEditModelForEntityType : GroupByEntity -> Model -> Maybe EditMode.EntityForm
getMaybeEditModelForEntityType entityType model =
    case ( entityType, model.editMode ) of
        ( GroupByProject, EditMode.EditProject editModel ) ->
            Just editModel

        ( GroupByContext, EditMode.EditContext editModel ) ->
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
        getDeletedEntityList GroupByContext model
    else
        Context.null :: getActiveEntityList GroupByContext model


getFilteredProjectList model =
    if model.showDeleted then
        getDeletedEntityList GroupByProject model
    else
        Project.null :: getActiveEntityList GroupByProject model


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
            |> updateTodoById [ time |> Todo.SnoozeTill ] todoId
            >> removeReminderOverlay


snoozeTodo todo m =
    m
        |> updateTodo
            [ Todo.SnoozeTill (m.now + (Time.minute * 10)) ]
            todo
        |> setReminderOverlayToInitialView todo


findAndSnoozeOverDueTodo model =
    findTodoWithOverDueReminder model
        ?|> apply2
                ( snoozeTodo # model
                , identity
                )


getActiveTodoListGroupedBy fn =
    getActiveTodoList >> Dict.Extra.groupBy (fn)


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (setProjectStore # model)
        |> (\( project, model ) -> startEditingEntity (ProjectEntity project) model)


createAndEditNewContext model =
    Store.insert (Project.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (setContextStore # model)
        |> (\( context, model ) -> startEditingEntity (ContextEntity context) model)



--updateTodoFromEditTodoForm : TodoForm -> ModelF
--updateTodoFromEditTodoForm { contextName, projectName, todoText, id, date, time } =
--    let
--        dateTimeString =
--            date ++ " " ++ time
--
--        maybeTime =
--            Date.fromString (dateTimeString)
--                !|> (Date.toTime >> Just)
--                != Nothing
--    in
--        apply3Uncurry ( findContextByName contextName, findProjectByName projectName, identity )
--            (\maybeContext maybeProject ->
--                updateTodoById
--                    [ Todo.SetText todoText
--                    , Todo.SetProjectId (maybeProject ?|> Document.getId ?= "")
--                    , Todo.SetContextId (maybeContext ?|> Document.getId ?= "")
--                    , Todo.SetTime maybeTime
--                    ]
--                    id
--            )


isShowDetailsKeyPressed =
    keyboardState.get >> Keyboard.isAltDown >> not


type alias Lens small big =
    { get : big -> small, set : small -> big -> big }


projectStore =
    { get = .projectStore, set = (\s b -> { b | projectStore = s }) }


keyboardState =
    { get = .keyboardState, set = (\s b -> { b | keyboardState = s }) }


todoStore =
    { get = .todoStore, set = (\s b -> { b | todoStore = s }) }


contextStore =
    { get = .contextStore, set = (\s b -> { b | contextStore = s }) }


now =
    { get = .now, set = (\s b -> { b | now = s }) }



--update lens smallF big =
--    lens.set (smallF (lens.get big)) big
--
--
--update2 lens l2 smallF big =
--    lens.set (smallF (l2.get big) (lens.get big)) big
--


activateNewTodoMode : String -> ModelF
activateNewTodoMode text =
    setEditMode (Todo.NewForm.create text |> EditMode.NewTodo)


startEditingTodo : Todo.Model -> ModelF
startEditingTodo todo =
    updateEditModeM (createEditTodoMode todo)


startEditingReminder : Todo.Model -> ModelF
startEditingReminder todo =
    updateEditModeM (createEditReminderTodoMode todo)


createEditReminderTodoMode : Todo.Model -> Model -> EditForm
createEditReminderTodoMode todo model =
    Todo.ReminderForm.create todo model.now |> EditMode.EditTodoReminder


startEditingTodoById : Todo.Id -> ModelF
startEditingTodoById id =
    applyMaybeWith (findTodoById id)
        (createEditTodoMode >> updateEditModeM)


startEditingEntity : Entity -> ModelF
startEditingEntity entity model =
    setEditMode (createEntityEditMode entity model) model


updateEditModeNameChanged newName entity model =
    case model.editMode of
        EditMode.EditContext ecm ->
            setEditMode (EditMode.editContextSetName newName ecm) model

        EditMode.EditProject epm ->
            setEditMode (EditMode.editProjectSetName newName epm) model

        _ ->
            model


toggleDeletedForEntity : Entity -> ModelF
toggleDeletedForEntity entity model =
    case entity of
        ContextEntity context ->
            context
                |> Document.toggleDeleted
                |> Context.setModifiedAt model.now
                |> (Store.update # model.contextStore)
                |> (setContextStore # model)

        ProjectEntity project ->
            project
                |> Document.toggleDeleted
                |> Project.setModifiedAt model.now
                |> (Store.update # model.projectStore)
                |> (setProjectStore # model)

        TodoEntity todo ->
            updateTodo [ Todo.ToggleDeleted ] todo model


saveCurrentForm model =
    case model.editMode of
        EditMode.EditContext form ->
            Store.findById form.id model.contextStore
                ?|> Context.setName form.name
                >> Context.setModifiedAt model.now
                >> (Store.update # model.contextStore)
                >> (setContextStore # model)
                ?= model

        EditMode.EditProject form ->
            Store.findById form.id model.projectStore
                ?|> Project.setName form.name
                >> Project.setModifiedAt model.now
                >> (Store.update # model.projectStore)
                >> (setProjectStore # model)
                ?= model

        EditMode.EditTodo form ->
            model |> updateTodoById [ Todo.SetText form.todoText ] form.id

        EditMode.EditTodoReminder form ->
            model |> updateTodoById [ Todo.SetTime (Todo.ReminderForm.getMaybeTime form) ] form.id

        EditMode.NewTodo form ->
            insertTodo (Todo.init model.now form.text) model
                |> Tuple.mapFirst Document.getId
                |> uncurry setTodoContextOrProjectBasedOnCurrentView

        EditMode.EditSyncSettings form ->
            { model | pouchDBRemoteSyncURI = form.uri }

        EditMode.None ->
            model


setTodoContextOrProjectBasedOnCurrentView todoId model =
    let
        maybeTodoUpdateAction =
            case model.mainViewType of
                EntityListView viewType ->
                    case viewType of
                        ContextView id ->
                            model.contextStore |> Store.findById id >>? Todo.SetContext

                        ProjectView id ->
                            model.projectStore |> Store.findById id >>? Todo.SetProject

                        _ ->
                            Nothing

                _ ->
                    Nothing

        maybeModel =
            maybeTodoUpdateAction
                ?|> (List.singleton >> updateTodoById # todoId # model)
    in
        maybeModel ?= model


createEntityEditMode : Entity -> Model -> EditForm
createEntityEditMode entity model =
    case entity of
        ContextEntity context ->
            EditMode.editContextMode context

        ProjectEntity project ->
            EditMode.editProjectMode project

        TodoEntity todo ->
            createEditTodoMode todo model


createEditTodoMode : Todo.Model -> Model -> EditForm
createEditTodoMode todo model =
    let
        projectName =
            getMaybeProjectNameOfTodo todo model ?= ""

        contextName =
            getContextNameOfTodo todo model ?= ""
    in
        Todo.Form.create todo |> EditMode.EditTodo


getMaybeEditTodoModel =
    getEditMode >> EditMode.getMaybeEditTodoModel


getEditNewTodoModel =
    getEditMode >> EditMode.getNewTodoModel


deactivateEditingMode =
    setEditMode EditMode.none


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


getFilteredTodoList model =
    let
        filter =
            model |> getCurrentTodoListFilter

        allTodos =
            model |> getTodoStore >> Store.asList

        sortFunction =
            model
                |> getCurrentTodoListSortByFunction
    in
        allTodos
            |> List.filter filter
            |> List.sortBy sortFunction
            |> List.take 25


getCurrentTodoListFilter model =
    case getMainViewType model of
        BinView ->
            Todo.binFilter

        DoneView ->
            Todo.doneFilter

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


findTodoById : Todo.Id -> Model -> Maybe Todo.Model
findTodoById id =
    getTodoStore >> Store.findById id


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


updateTodo : List Todo.UpdateAction -> Todo.Model -> ModelF
updateTodo action todo =
    apply2With ( getNow, getTodoStore )
        ((Todo.update action # todo)
            >> Store.update
            >>> setTodoStore
        )


updateTodoById actions todoId =
    applyMaybeWith (findTodoById todoId)
        (updateTodo actions)


replaceTodoIfEqualById todo =
    List.replaceIf (Document.equalById todo) todo


insertTodo : (Document.Id -> Todo.Model) -> Model -> ( Todo.Model, Model )
insertTodo constructWithId =
    applyWith (getTodoStore)
        (Store.insert (constructWithId) >> setTodoStoreFromTuple)


setTodoStoreFromTuple tuple model =
    tuple |> Tuple.mapSecond (setTodoStore # model)


onExternalEntityChange dbName encodedEntity =
    case dbName of
        "todo-db" ->
            updateTodoStore (Store.updateExternal encodedEntity)

        "project-db" ->
            updateProjectStoreM (getProjectStore >> Store.updateExternal encodedEntity)

        "context-db" ->
            updateContextStoreM (getContextStore >> Store.updateExternal encodedEntity)

        _ ->
            identity


getMainViewType : Model -> MainViewType
getMainViewType =
    (.mainViewType)


setMainViewType_ : MainViewType -> ModelF
setMainViewType_ mainViewType model =
    { model | mainViewType = mainViewType }


setMainViewType : MainViewType -> ModelF
setMainViewType mainViewType =
    setMainViewType_ mainViewType


getEntityId entity =
    case entity of
        TodoEntity doc ->
            Document.getId doc

        ProjectEntity doc ->
            Document.getId doc

        ContextEntity doc ->
            Document.getId doc


getFocusedEntityIndex entityList model =
    entityList
        |> List.findIndex (getEntityId >> equals model.focusedEntityInfo.id)
        ?= 0


focusEntityByIndex entityList index model =
    let
        focusedEntityIndex =
            List.clampIndex index entityList

        focusedEntityId =
            focusedEntityIndex
                |> (List.getAt # entityList)
                ?|> getEntityId
                ?= ""

        focusedEntityInfo =
            { id = focusedEntityId, index = focusedEntityIndex }
    in
        { model | focusedEntityInfo = focusedEntityInfo }


focusEntityById focusInside id model =
    let
        focusedEntityInfo =
            model.focusedEntityInfo
    in
        { model | focusedEntityInfo = { focusedEntityInfo | id = id } }


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


focusPrevEntity : List Entity -> ModelF
focusPrevEntity entityList model =
    getFocusedEntityIndex entityList model
        |> andThenSubtract 1
        |> (focusEntityByIndex entityList # model)


focusNextEntity : List Entity -> ModelF
focusNextEntity entityList model =
    getFocusedEntityIndex entityList model
        |> add 1
        |> (focusEntityByIndex entityList # model)


createViewEntityList viewType model =
    case viewType of
        GroupByContextView ->
            let
                contextList =
                    getFilteredContextList model
            in
                getContextsViewEntityList contextList model

        ContextView id ->
            let
                contextList =
                    model.contextStore |> Store.findById id ?= Context.null |> List.singleton
            in
                getContextsViewEntityList contextList model

        GroupByProjectView ->
            let
                projectList =
                    getFilteredProjectList model
            in
                getProjectsViewEntityList projectList model

        ProjectView id ->
            let
                projectList =
                    model.projectStore |> Store.findById id ?= Project.null |> List.singleton
            in
                getProjectsViewEntityList projectList model


getContextsViewEntityList contextList model =
    let
        -- todo : use getFiltered todo list
        todoListByContextId =
            getActiveTodoListGroupedBy Todo.getContextId model

        todoEntitiesForContext context =
            todoListByContextId
                |> Dict.get (Document.getId context)
                ?= []
                .|> TodoEntity
    in
        contextList
            |> List.concatMap
                (\context ->
                    (ContextEntity context) :: (todoEntitiesForContext context)
                )


getProjectsViewEntityList projectList model =
    let
        -- todo : use getFiltered todo list
        todoListByProjectId =
            getActiveTodoListGroupedBy Todo.getProjectId model

        todoEntitiesForProject project =
            todoListByProjectId
                |> Dict.get (Document.getId project)
                ?= []
                .|> TodoEntity
    in
        projectList
            |> List.concatMap
                (\project ->
                    (ProjectEntity project) :: (todoEntitiesForProject project)
                )
