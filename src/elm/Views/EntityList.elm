module Views.EntityList exposing (..)

import Data.EntityTree exposing (GroupDocEntityNode(..), TodoListNode(..), TodoListNodeTitle(TitleWithTotalCount), Tree(..))
import Entity exposing (GroupDocEntity(..))
import GroupDoc exposing (GroupDocType(..))
import GroupDoc.View
import Html
import Html.Attributes exposing (class)
import Html.Keyed
import Todo.ItemView
import Toolkit.Operators exposing (..)
import Views.Badge


view pageVM =
    Html.Keyed.node "div"
        [ class "entity-list focusable-list"
        ]
        (keyedViewList pageVM)


keyedViewList pageVM =
    let
        createGroupDocVM gdType gDoc todoList =
            case gdType of
                ContextGroupDocType ->
                    pageVM.createContextGroupVM
                        todoList
                        gDoc

                ProjectGroupDocType ->
                    pageVM.createProjectGroupVM
                        todoList
                        gDoc

        createGroupDocHeaderView (GroupDocEntityNode (GroupDocEntity gdType gDoc) todoList) =
            groupHeaderView (createGroupDocVM gdType gDoc todoList)

        createGroupDocView (GroupDocEntityNode (GroupDocEntity gdType gDoc) todoList) =
            groupView createTodoView (createGroupDocVM gdType gDoc todoList)

        createTodoView todo =
            todo
                |> pageVM.createTodoViewModel
                |> Todo.ItemView.keyedItem

        createKeyedViewList tree =
            case tree of
                GroupDocTree gdNode nodeList ->
                    [ createGroupDocHeaderView gdNode ]
                        ++ (nodeList .|> createGroupDocView)

                GroupDocForest nodeList ->
                    nodeList .|> createGroupDocView

                TodoList (TodoListNode (TitleWithTotalCount title totalCount) todoList) ->
                    List.map createTodoView todoList
                        |> flatTodoListView title totalCount

                TodoListForest nodeList ->
                    nodeList |> List.concatMap (TodoList >> createKeyedViewList)
    in
    createKeyedViewList pageVM.entityTree


groupView todoView vm =
    GroupDoc.View.initKeyed todoView vm


groupHeaderView vm =
    GroupDoc.View.initHeaderKeyed vm


flatTodoListView title totalCount todoListView =
    let
        titleKeyedView =
            let
                count =
                    todoListView |> List.length

                titleSuffix =
                    count
                        :: (if totalCount > 0 then
                                [ totalCount ]
                            else
                                []
                           )
                        .|> toString
                        |> String.join "/"
            in
            ( title
            , Html.div [ class "collection-item" ]
                [ Html.h5 [] [ Views.Badge.badgeStringSuffix title titleSuffix ] ]
            )

        truncatedKeyedViewList =
            todoListView
                |> List.take totalCount

        view =
            Html.Keyed.node "div"
                [ class "todo-list collection" ]
                (titleKeyedView :: todoListView)
    in
    [ ( title, view ) ]
