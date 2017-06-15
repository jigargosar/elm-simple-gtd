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


listView : Entity.ListViewType -> Model.Model -> ViewModel.Model -> Html.Html Msg
listView viewType model appViewModel =
    let
        grouping =
            Model.createGrouping viewType model

        entityList =
            grouping |> Entity.flattenGrouping

        maybeFocusInEntity =
            Model.getMaybeFocusInEntity entityList model

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

        keyedViewList =
            let
                createContextVM { context, todoList } =
                    EntityList.ViewModel.contextGroup
                        getTabIndexAVForEntity
                        todoList
                        context

                multiContextView list =
                    list .|> (createContextVM >> groupView appViewModel)

                createProjectVM { project, todoList } =
                    EntityList.ViewModel.projectGroup
                        getTabIndexAVForEntity
                        todoList
                        project

                multiProjectView list =
                    list .|> (createProjectVM >> groupView appViewModel)
            in
                case grouping of
                    Entity.SingleContext contextGroup subGroupList ->
                        let
                            header =
                                createContextVM contextGroup |> groupHeaderView appViewModel
                        in
                            header :: multiProjectView subGroupList

                    Entity.SingleProject projectGroup subGroupList ->
                        let
                            header =
                                createProjectVM projectGroup |> groupHeaderView appViewModel
                        in
                            header :: multiContextView subGroupList

                    Entity.MultiContext groupList ->
                        multiContextView groupList

                    Entity.MultiProject groupList ->
                        multiProjectView groupList

                    Entity.FlatTodoList todoList ->
                        let
                            getTabIndexAVForTodo =
                                Entity.TodoEntity >> getTabIndexAVForEntity
                        in
                            todoList
                                .|> (\todo ->
                                        appViewModel.createTodoViewModel (getTabIndexAVForTodo todo) todo
                                            |> Todo.View.initKeyed
                                    )
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Model.OnEntityListKeyDown entityList |> onKeyDown
            ]
            keyedViewList


groupView appViewModel vm =
    EntityList.GroupView.initKeyed appViewModel vm


groupHeaderView appViewModel vm =
    EntityList.GroupView.initHeaderKeyed appViewModel vm
