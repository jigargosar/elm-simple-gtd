module Views.EntityList exposing (..)

import Data.EntityTree exposing (GroupDocNode(..), Tree(..))
import Entity exposing (GroupDocEntity(..))
import GroupDoc exposing (GroupDocType(..))
import GroupDoc.View
import Html exposing (div, h5)
import Html.Attributes exposing (class)
import Html.Keyed
import Todo.ItemView
import Toolkit.Operators exposing (..)
import View.Badge


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

        createGroupDocHeaderView (GroupDocNode (GroupDocEntity gdType gDoc) todoList) =
            groupHeaderView (createGroupDocVM gdType gDoc todoList)

        createGroupDocView (GroupDocNode (GroupDocEntity gdType gDoc) todoList) =
            groupView createTodoView (createGroupDocVM gdType gDoc todoList)

        createTodoView todo =
            todo
                |> pageVM.createTodoViewModel
                |> Todo.ItemView.keyedItem
    in
    case pageVM.entityTree of
        FlatTodoList title todoList totalCount ->
            List.map createTodoView todoList
                |> flatTodoListView title totalCount

        GroupDocTree gdNode nodeList ->
            [ createGroupDocHeaderView gdNode ]
                ++ (nodeList .|> createGroupDocView)

        GroupDocForest nodeList ->
            nodeList .|> createGroupDocView


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
                    [ count, totalCount ]
                        .|> toString
                        |> String.join "/"
            in
            ( title
            , div [ class "collection-item" ]
                [ h5 [] [ View.Badge.badgeStringSuffix title titleSuffix ] ]
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
