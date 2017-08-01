module Views.EntityList exposing (..)

import Entity
import Entity.Tree
import EntityId
import GroupDoc.View
import Html exposing (div, h5)
import Html.Attributes exposing (class)
import Html.Keyed
import List.Extra as List
import Maybe.Extra as Maybe
import Pages.EntityList
import Todo.ItemView
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import View.Badge
import X.Function exposing (..)
import X.Function.Infix exposing (..)


view config appVM appModel model =
    let
        entityTree =
            Pages.EntityList.createEntityTree model appModel

        entityList =
            Entity.Tree.flatten entityTree

        maybeEntityIdAtCursorOld =
            Pages.EntityList.computeMaybeNewEntityIdAtCursor model appModel
                ?+> (Entity.hasId >> List.find # entityList)
                |> Maybe.orElse (List.head entityList)
                ?|> Entity.toEntityId
    in
    Html.Keyed.node "div"
        [ class "entity-list focusable-list"
        ]
        (keyedViewList maybeEntityIdAtCursorOld appVM entityTree)


keyedViewList maybeEntityIdAtCursorOld appVM entityTree =
    let
        isCursorAtEntityId entityId =
            maybeEntityIdAtCursorOld ?|> equals entityId ?= False

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
                |> appVM.createTodoViewModel isFocusable
                |> Todo.ItemView.keyedItem

        --        todoListView : List TodoDoc -> List KeyedView
        todoListView =
            List.map todoViewFromTodo
    in
    case entityTree of
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
