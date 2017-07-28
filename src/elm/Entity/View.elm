module Entity.View exposing (list)

import Entity
import Entity.Tree
import EntityId
import EntityListCursor
import GroupDoc.View
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Keyed
import List.Extra
import Maybe.Extra
import Model
import Model.EntityTree
import Todo.ItemView
import Toolkit.Operators exposing (..)
import View.Badge
import X.Function exposing (..)
import X.Keyboard exposing (onKeyDown)


--type alias KeyedView =
--    ( String, Html AppMsg )
--list : EntityListViewType -> AppModel -> Html.Html AppMsg


list config appVM viewType model =
    let
        entityTree =
            Model.EntityTree.createEntityTreeForViewType viewType model

        entityList =
            entityTree |> Entity.Tree.flatten

        maybeEntityIdAtCursor =
            getMaybeEntityIdAtCursor entityList model
    in
    Html.Keyed.node "div"
        [ class "entity-list focusable-list"
        , config.onEntityListKeyDown entityList |> onKeyDown
        ]
        (keyedViewList appVM entityTree maybeEntityIdAtCursor model)


getMaybeEntityIdAtCursor entityList model =
    EntityListCursor.getMaybeEntityIdAtCursor model
        ?+> (Entity.hasId >> List.Extra.find # entityList)
        |> Maybe.Extra.orElse (List.head entityList)
        ?|> Entity.toEntityId


keyedViewList appVM grouping maybeEntityIdAtCursor model =
    let
        isCursorAtEntityId entityId =
            maybeEntityIdAtCursor ?|> equals entityId ?= False

        getTabIndexForEntityId entityId =
            if isCursorAtEntityId entityId then
                0
            else
                -1

        createContextVM { context, todoList } =
            appVM.createContextGroupVM
                getTabIndexForEntityId
                todoList
                context

        multiContextView list =
            list .|> (createContextVM >> groupView todoViewFromTodo)

        createProjectVM { project, todoList } =
            appVM.createProjectGroupVM
                getTabIndexForEntityId
                todoList
                project

        multiProjectView list =
            list .|> (createProjectVM >> groupView todoViewFromTodo)

        --        todoViewFromTodo : TodoDoc -> KeyedView
        todoViewFromTodo todo =
            let
                isFocusable =
                    EntityId.fromTodo todo |> isCursorAtEntityId
            in
            todo
                |> appVM.createTodoViewModel model isFocusable
                |> Todo.ItemView.keyedItem

        --        todoListView : List TodoDoc -> List KeyedView
        todoListView =
            List.map todoViewFromTodo
    in
    case grouping of
        Entity.Tree.ContextRoot contextGroup subGroupList ->
            let
                header =
                    createContextVM contextGroup |> groupHeaderView
            in
            header :: multiProjectView subGroupList

        Entity.Tree.ProjectRoot projectGroup subGroupList ->
            let
                header =
                    createProjectVM projectGroup |> groupHeaderView
            in
            header :: multiContextView subGroupList

        Entity.Tree.ContextForest groupList ->
            multiContextView groupList

        Entity.Tree.ProjectForest groupList ->
            multiProjectView groupList

        Entity.Tree.TodoForest title todoList ->
            todoListView todoList
                |> flatTodoListView title


groupView todoView vm =
    GroupDoc.View.initKeyed todoView vm



--groupHeaderView : GroupDocViewModel -> KeyedView


groupHeaderView vm =
    GroupDoc.View.initHeaderKeyed vm


flatTodoListView title todoListView =
    let
        count =
            todoListView |> List.length

        truncatedList =
            todoListView |> List.take 75
    in
    [ ( title
      , Html.Keyed.node "div"
            [ class "todo-list collection" ]
            (( title, div [ class "collection-item" ] [ h5 [] [ View.Badge.badge title count ] ] ) :: truncatedList)
      )
    ]
