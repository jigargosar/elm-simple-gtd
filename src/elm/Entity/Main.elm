module Entity.Main exposing (..)

import Context
import Document
import Document.Types exposing (getDocId)
import DomPorts
import Entity
import Entity.Types exposing (Entity(GroupEntity, TodoEntity), EntityListViewType(BinView, ContextView, ContextsView, DoneView, ProjectView, ProjectsView, RecentView), GroupEntityType(ContextEntity, ProjectEntity), createContextEntity, createProjectEntity)
import ExclusiveMode.Types exposing (ExclusiveMode(XMEditContext, XMEditProject, XMEditTodo))
import GroupDoc
import GroupDoc.EditForm
import Model.Internal exposing (setEditMode, setTodoEditForm)
import Model.Selection
import Model.ViewType
import Msg exposing (Msg)
import Project
import Return
import Set
import Store
import Stores
import Time exposing (Time)
import Todo
import Todo.Form
import Todo.Msg
import Todo.Types exposing (TodoAction(..))
import Types exposing (ModelF, ModelReturnF, ReturnF)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function.Infix exposing (..)


map =
    Return.map


update :
    (Msg -> ReturnF)
    -> Entity.Types.EntityMsg
    -> ReturnF
update andThenUpdate msg =
    case msg of
        Entity.Types.OnNewProject ->
            map createAndEditNewProject
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNewContext ->
            map createAndEditNewContext
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnUpdate entity entityUpdateMsg ->
            onUpdate andThenUpdate entity entityUpdateMsg


onUpdate :
    (Msg -> ReturnF)
    -> Entity
    -> Entity.Types.EntityUpdateMsg
    -> ReturnF
onUpdate andThenUpdate entity msg =
    case msg of
        Entity.Types.OnStartEditing ->
            Return.map (\model -> startEditingEntity model.now entity model)
                >> DomPorts.autoFocusInputCmd

        Entity.Types.OnNameChanged newName ->
            Return.map (updateEditModeNameChanged newName entity)

        Entity.Types.OnSave ->
            andThenUpdate Msg.OnSaveCurrentForm

        Entity.Types.OnToggleDeleted ->
            Return.andThen (toggleDeleteEntity entity)
                >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnToggleArchived ->
            let
                toggleArchivedEntity entity =
                    let
                        entityId =
                            Entity.getId entity
                    in
                        case entity of
                            Entity.Types.GroupEntity g ->
                                (case g of
                                    Entity.Types.ContextEntity context ->
                                        Stores.updateContext entityId GroupDoc.toggleArchived

                                    Entity.Types.ProjectEntity project ->
                                        Stores.updateProject entityId GroupDoc.toggleArchived
                                )
                                    |> Return.andThen

                            Entity.Types.TodoEntity todo ->
                                Todo.Msg.OnUpdateTodoAndMaybeSelectedAndDeactivateEditingMode entityId TA_ToggleDone
                                    |> Msg.OnTodoMsg
                                    |> andThenUpdate
            in
                toggleArchivedEntity entity
                    >> andThenUpdate Msg.OnDeactivateEditingMode

        Entity.Types.OnOnFocusIn ->
            Return.map (Stores.setFocusInEntity entity)

        Entity.Types.OnToggleSelected ->
            Return.map (toggleEntitySelection entity)

        Entity.Types.OnGoto ->
            Return.map (switchToEntityListViewFromEntity entity)


toggleEntitySelection entity =
    Model.Selection.updateSelectedEntityIdSet (toggleSetMember (Entity.getId entity))


toggleSetMember item set =
    if Set.member item set then
        Set.remove item set
    else
        Set.insert item set


switchToEntityListViewFromEntity entity model =
    let
        maybeEntityListViewType =
            Model.ViewType.maybeGetCurrentEntityListViewType model
    in
        entity
            |> toViewType maybeEntityListViewType
            |> (Model.ViewType.setEntityListViewType # model)


toggleDeleteEntity : Entity -> ModelReturnF
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
                            Stores.updateContext entityId Document.toggleDeleted

                        Entity.Types.ProjectEntity project ->
                            Stores.updateProject entityId Document.toggleDeleted

                Entity.Types.TodoEntity todo ->
                    Stores.updateTodo (TA_ToggleDeleted) entityId


createAndEditNewProject model =
    Store.insert (Project.init "<New Project>" model.now) model.projectStore
        |> Tuple2.mapSecond (Stores.setProjectStore # model)
        |> (\( project, model ) ->
                model
                    |> startEditingEntity model.now (createProjectEntity project)
           )


createAndEditNewContext model =
    Store.insert (Context.init "<New Context>" model.now) model.contextStore
        |> Tuple2.mapSecond (Stores.setContextStore # model)
        |> (\( context, model ) ->
                model
                    |> startEditingEntity model.now (createContextEntity context)
           )


editProjectSetName =
    GroupDoc.EditForm.setName >>> XMEditProject


editContextSetName =
    GroupDoc.EditForm.setName >>> XMEditContext


startEditingEntity : Time -> Entity -> ModelF
startEditingEntity now entity model =
    model
        |> case entity of
            GroupEntity g ->
                case g of
                    ContextEntity context ->
                        setEditMode (context |> GroupDoc.EditForm.forContext >> XMEditContext)

                    ProjectEntity p ->
                        setEditMode (p |> GroupDoc.EditForm.forProject >> XMEditProject)

            TodoEntity todo ->
                setEditMode XMEditTodo
                    >> setTodoEditForm (Todo.Form.createEditTodoForm now todo)


updateEditModeNameChanged newName entity model =
    model
        |> case model.editMode of
            XMEditContext ecm ->
                setEditMode (editContextSetName newName ecm)

            XMEditProject epm ->
                setEditMode (editProjectSetName newName epm)

            _ ->
                identity


toViewType : Maybe EntityListViewType -> Entity -> EntityListViewType
toViewType maybePrevView entity =
    case entity of
        GroupEntity group ->
            case group of
                ContextEntity model ->
                    getDocId model |> ContextView

                ProjectEntity model ->
                    getDocId model |> ProjectView

        TodoEntity model ->
            maybePrevView
                ?|> getTodoGotoGroupView model
                ?= (Todo.getContextId model |> ContextView)


getTodoGotoGroupView todo prevView =
    let
        contextView =
            Todo.getContextId todo |> ContextView

        projectView =
            Todo.getProjectId todo |> ProjectView
    in
        case prevView of
            ProjectsView ->
                contextView

            ProjectView _ ->
                contextView

            ContextsView ->
                projectView

            ContextView _ ->
                projectView

            BinView ->
                ContextsView

            DoneView ->
                ContextsView

            RecentView ->
                ContextsView
