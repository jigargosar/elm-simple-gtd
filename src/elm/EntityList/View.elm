module EntityList.View exposing (..)

import Document
import Entity exposing (Entity)
import EntityList.GroupView
import EntityList.GroupView2
import EntityList.GroupViewModel exposing (DocumentWithName)
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


type alias GroupViewModel =
    EntityList.GroupViewModel.ViewModel


type ViewModel
    = Context GroupViewModel
    | Project GroupViewModel
    | Todo TodoViewModel


type VM2
    = Multi (List EntityList.ViewModel.GroupViewModel)


{-| todo: refactoring: build tree in model then flatten it there , don't build tree here, its easier there
-}
updateCount vmList =
    vmList
        |> List.foldr
            (\vm ( vmList, count ) ->
                case vm of
                    Context vm ->
                        ( Context { vm | count = count } :: vmList, 0 )

                    Project vm ->
                        ( Project { vm | count = count } :: vmList, 0 )

                    Todo vm ->
                        ( Todo vm :: vmList, count + 1 )
            )
            ( [], 0 )
        |> Tuple.first
        |> (\list ->
                case list of
                    (Context vm) :: (Project pvm) :: rest ->
                        let
                            isTodo vm =
                                case vm of
                                    Todo vm ->
                                        True

                                    _ ->
                                        False

                            totalTodoCount =
                                vmList |> List.filter (isTodo) |> List.length
                        in
                            (Context { vm | count = totalTodoCount }) :: Project pvm :: rest

                    (Project vm) :: (Context cvm) :: rest ->
                        let
                            isTodo vm =
                                case vm of
                                    Todo vm ->
                                        True

                                    _ ->
                                        False

                            totalTodoCount =
                                vmList |> List.filter (isTodo) |> List.length
                        in
                            (Project { vm | count = totalTodoCount }) :: Context cvm :: rest

                    _ ->
                        list
           )


createVMList : List Entity.Entity -> ViewModel.Model -> Model.Model -> List ViewModel
createVMList entityList appViewModel model =
    let
        maybeFocusInEntity =
            Model.getMaybeFocusInEntity entityList model

        hasFocusIn entity =
            maybeFocusInEntity ?|> Entity.equalById entity ?= False

        getTabindexAV entity =
            let
                tabindexValue =
                    if hasFocusIn entity then
                        0
                    else
                        -1
            in
                tabindex tabindexValue

        createVM entity =
            let
                tabIndexAV =
                    getTabindexAV entity
            in
                case entity of
                    Entity.ContextEntity context ->
                        EntityList.GroupViewModel.forContext tabIndexAV context
                            |> Context

                    Entity.ProjectEntity project ->
                        EntityList.GroupViewModel.forProject tabIndexAV project
                            |> Project

                    Entity.TodoEntity todo ->
                        appViewModel.createTodoViewModel tabIndexAV todo
                            |> Todo
    in
        entityList .|> createVM |> updateCount


listView : Entity.ListViewType -> Model.Model -> ViewModel.Model -> Html.Html Msg
listView viewType model appViewModel =
    let
        grouping =
            Model.createGrouping viewType model

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

        tempList =
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

        entityList =
            grouping |> Entity.flattenGrouping

        vmList =
            createVMList entityList appViewModel model

        createEntityView vm =
            case vm of
                Context vm ->
                    EntityList.GroupView.initKeyed vm

                Project vm ->
                    EntityList.GroupView.initKeyed vm

                Todo vm ->
                    Todo.View.initKeyed vm
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Model.OnEntityListKeyDown entityList |> onKeyDown
            ]
            {- (vmList
                   .|> createEntityView
               )
            -}
            tempList


groupView appViewModel vm =
    EntityList.GroupView2.initKeyed appViewModel vm


groupHeaderView appViewModel vm =
    EntityList.GroupView2.initHeaderKeyed appViewModel vm
