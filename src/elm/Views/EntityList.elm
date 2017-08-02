module Views.EntityList exposing (..)

import Data.EntityTree
import Entity
import EntityId
import GroupDoc.View
import Html exposing (div, h5)
import Html.Attributes exposing (class)
import Html.Keyed
import List.Extra as List
import Maybe.Extra as Maybe
import Pages.EntityList
import Todo.ItemView
import Toolkit.Operators exposing (..)
import View.Badge
import X.Function exposing (..)


view config appVM appModel model =
    let
        entityTree =
            Pages.EntityList.createEntityTree model appModel

        entityList =
            Data.EntityTree.flatten entityTree

        maybeEntityIdAtCursor =
            Pages.EntityList.computeMaybeNewEntityIdAtCursor model appModel
                ?+> (Entity.hasId >> List.find # entityList)
                |> Maybe.orElse (List.head entityList)
                ?|> Entity.toEntityId
    in
    Html.Keyed.node "div"
        [ class "entity-list focusable-list"
        ]
        (keyedViewList maybeEntityIdAtCursor appVM entityTree)


keyedViewList maybeEntityIdAtCursor appVM entityTree =
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
                |> appVM.createTodoViewModel isFocusable
                |> Todo.ItemView.keyedItem

        --        todoListView : List TodoDoc -> List KeyedView
        todoListView =
            List.map todoViewFromTodo
    in
    case entityTree of
        Data.EntityTree.ContextRoot contextGroup subGroupList ->
            let
                header =
                    createContextVM contextGroup |> groupHeaderView
            in
            header :: multiProjectView subGroupList

        Data.EntityTree.ProjectRoot projectGroup subGroupList ->
            let
                header =
                    createProjectVM projectGroup |> groupHeaderView
            in
            header :: multiContextView subGroupList

        Data.EntityTree.ContextForest groupList ->
            multiContextView groupList

        Data.EntityTree.ProjectForest groupList ->
            multiProjectView groupList

        Data.EntityTree.TodoForest title todoList ->
            todoListView todoList
                |> flatTodoListView title

        Data.EntityTree.Root node ->
            case node of
                Data.EntityTree.Node (Data.EntityTree.StringTitle title) todoList ->
                    todoListView todoList
                        |> flatTodoListView title

                _ ->
                    [ ( "0", div [] [] ) ]

        Data.EntityTree.Forest list node ->
            [ ( "0", div [] [] ) ]


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
