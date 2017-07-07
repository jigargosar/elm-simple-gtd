module Entity.View exposing (..)

import Entity exposing (Entity)
import Entity.Tree
import GroupDoc.View
import GroupDoc.ViewModel
import Html
import Toolkit.Operators exposing (..)
import X.Keyboard exposing (onKeyDown)
import Html.Attributes exposing (class, tabindex)
import Html.Keyed
import Model
import Msg exposing (..)
import Todo.View exposing (TodoViewModel)
import ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import View.Shared exposing (badge)


list : Entity.ListViewType -> Model.Model -> Html.Html Msg
list viewType model =
    let
        grouping =
            Model.createGrouping viewType model

        entityList =
            grouping |> Entity.Tree.flatten

        maybeFocusInEntity =
            Model.getMaybeFocusInEntity entityList model
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (keyedViewList grouping maybeFocusInEntity model)


keyedViewList grouping maybeFocusInEntity model =
    let
        hasFocusIn entity =
            maybeFocusInEntity ?|> Entity.equalById entity ?= False

        getTabIndexForEntity entity =
            if hasFocusIn entity then
                0
            else
                -1

        createContextVM { context, todoList } =
            GroupDoc.ViewModel.contextGroup
                getTabIndexForEntity
                todoList
                context

        multiContextView list =
            list .|> (createContextVM >> groupView todoView)

        createProjectVM { project, todoList } =
            GroupDoc.ViewModel.projectGroup
                getTabIndexForEntity
                todoList
                project

        multiProjectView list =
            list .|> (createProjectVM >> groupView todoView)

        todoView todo =
            let
                canBeFocused =
                    Entity.Todo todo |> hasFocusIn
            in
                todo
                    |> Todo.View.createTodoViewModel model canBeFocused
                    |> Todo.View.keyedItem

        todoListView =
            List.map todoView
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
                (( title, div [ class "collection-item" ] [ h5 [] [ badge title count ] ] ) :: truncatedList)
          )
        ]
