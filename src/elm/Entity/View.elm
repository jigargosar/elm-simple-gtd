module Entity.View exposing (..)

import Entity
import Entity.Tree
import Entity.Types exposing (EntityListViewType)
import EntityId
import GroupDoc.View
import GroupDoc.ViewModel exposing (GroupDocViewModel)
import Html
import List.Extra
import Maybe.Extra
import Model.EntityTree
import Todo.ItemView
import Todo.Types exposing (TodoDoc)
import Todo.ViewModel
import Toolkit.Operators exposing (..)
import Types exposing (AppModel)
import X.Keyboard exposing (onKeyDown)
import Html.Attributes exposing (class, tabindex)
import Html.Keyed
import Msg exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import View.Badge


type alias KeyedView =
    ( String, Html AppMsg )


list : EntityListViewType -> AppModel -> Html.Html AppMsg
list viewType model =
    let
        grouping =
            Model.EntityTree.createEntityTreeForViewType viewType model

        entityList =
            grouping |> Entity.Tree.flatten

        maybeFocusInEntity =
            getMaybeFocusInEntity entityList model
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Msg.onEntityListKeyDown entityList |> onKeyDown
            ]
            (keyedViewList grouping maybeFocusInEntity model)


getMaybeFocusInEntity entityList model =
    entityList
        |> List.Extra.find (Entity.equalById model.focusInEntity)
        |> Maybe.Extra.orElse (List.head entityList)


keyedViewList grouping maybeFocusInEntity model =
    let
        entityIdHasFocusIn entityId =
            maybeFocusInEntity ?|> Entity.hasEntityId entityId ?= False

        getTabIndexForEntityId entityId =
            if entityIdHasFocusIn entityId then
                0
            else
                -1

        createContextVM { context, todoList } =
            GroupDoc.ViewModel.contextGroup
                getTabIndexForEntityId
                todoList
                context

        multiContextView list =
            list .|> (createContextVM >> groupView todoViewFromTodo)

        createProjectVM { project, todoList } =
            GroupDoc.ViewModel.projectGroup
                getTabIndexForEntityId
                todoList
                project

        multiProjectView list =
            list .|> (createProjectVM >> groupView todoViewFromTodo)

        todoViewFromTodo : TodoDoc -> KeyedView
        todoViewFromTodo todo =
            let
                isFocusable =
                    EntityId.fromTodo todo |> entityIdHasFocusIn
            in
                todo
                    |> Todo.ViewModel.createTodoViewModel model isFocusable
                    |> Todo.ItemView.keyedItem

        todoListView : List TodoDoc -> List KeyedView
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


groupHeaderView : GroupDocViewModel -> KeyedView
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
