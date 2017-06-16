module EntityList.View exposing (..)

import Document
import Entity exposing (Entity)
import EntityList.GroupView
import EntityList.ViewModel
import Html
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Ext.Keyboard exposing (onKeyDown)
import Html.Attributes exposing (class, tabindex)
import Html.Keyed
import Model
import Model exposing (Msg)
import Todo.View exposing (TodoViewModel)
import ViewModel
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)


listView : Entity.ListViewType -> Model.Model -> ViewModel.Model -> Html.Html Msg
listView viewType model appViewModel =
    let
        grouping =
            Model.createGrouping viewType model

        entityList =
            grouping |> Entity.flattenGrouping

        maybeFocusInEntity =
            Model.getMaybeFocusInEntity entityList model
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Model.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (keyedViewList grouping maybeFocusInEntity appViewModel)


keyedViewList grouping maybeFocusInEntity appViewModel =
    let
        hasFocusIn entity =
            maybeFocusInEntity ?|> Entity.equalById entity ?= False

        getTabIndexAVForEntity entity =
            let
                tabindexValue =
                    if hasFocusIn entity then
                        0
                    else
                        -1
            in
                tabindex tabindexValue

        createContextVM { context, todoList } =
            EntityList.ViewModel.contextGroup
                getTabIndexAVForEntity
                todoList
                context

        multiContextView list =
            list .|> (createContextVM >> groupView todoView)

        createProjectVM { project, todoList } =
            EntityList.ViewModel.projectGroup
                getTabIndexAVForEntity
                todoList
                project

        multiProjectView list =
            list .|> (createProjectVM >> groupView todoView)

        todoView todo =
            let
                tabIndexAV =
                    Entity.TodoEntity todo |> getTabIndexAVForEntity
            in
                todo
                    |> Todo.View.createTodoViewModel appViewModel tabIndexAV
                    |> Todo.View.initKeyed

        todoListView =
            List.map todoView
    in
        case grouping of
            Entity.SingleContext contextGroup subGroupList ->
                let
                    header =
                        createContextVM contextGroup |> groupHeaderView
                in
                    header :: multiProjectView subGroupList

            Entity.SingleProject projectGroup subGroupList ->
                let
                    header =
                        createProjectVM projectGroup |> groupHeaderView
                in
                    header :: multiContextView subGroupList

            Entity.MultiContext groupList ->
                multiContextView groupList

            Entity.MultiProject groupList ->
                multiProjectView groupList

            Entity.FlatTodoList title todoList ->
                todoListView todoList
                    |> flatTodoListView title


groupView todoView vm =
    EntityList.GroupView.initKeyed todoView vm


groupHeaderView vm =
    EntityList.GroupView.initHeaderKeyed vm


flatTodoListView title todoListView =
    [ ( title
      , Html.Keyed.node "div"
            [ class "todo-list collection" ]
            (( title, div [ class "collection-item" ] [ h4 [] [ text title ] ] ) :: todoListView)
      )
    ]
