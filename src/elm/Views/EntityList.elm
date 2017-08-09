module Views.EntityList exposing (..)

import Data.EntityTree
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
        createContextVM { context, todoList } =
            pageVM.createContextGroupVM
                todoList
                context

        multiContextView list =
            list .|> (createContextVM >> groupView createTodoView)

        createProjectVM { project, todoList } =
            pageVM.createProjectGroupVM
                todoList
                project

        multiProjectView list =
            list .|> (createProjectVM >> groupView createTodoView)

        createTodoView todo =
            todo
                |> pageVM.createTodoViewModel
                |> Todo.ItemView.keyedItem
    in
    case pageVM.entityTree of
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

        Data.EntityTree.Root node totalCount ->
            case node of
                Data.EntityTree.Node (Data.EntityTree.StringTitle title) todoList ->
                    List.map createTodoView todoList
                        |> flatTodoListView title totalCount

                _ ->
                    [ ( "0", div [] [] ) ]

        Data.EntityTree.Forest nodeList ->
            [ ( "0", div [] [] ) ]


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
