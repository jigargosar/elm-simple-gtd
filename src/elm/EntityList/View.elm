module EntityList.View exposing (..)

import Document
import Entity exposing (Entity)
import EntityList.GroupView
import EntityList.GroupViewModel exposing (DocumentWithName)
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


type alias EntityViewModel =
    { id : Document.Id
    , onFocusIn : Msg
    , startEditingMsg : Msg
    , toggleDeleteMsg : Msg
    , startEditingMsg : Msg
    , tabIndexAV : Html.Attribute Msg
    }


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

        _ =
            case grouping of
                Entity.SingleContext { context, list } projectSubgroups ->
                    identity

        entityList =
            grouping |> Entity.flattenGrouping

        vmList =
            createVMList entityList appViewModel model

        createEntityView vm =
            case vm of
                Context vm ->
                    EntityList.GroupView.initKeyed appViewModel vm

                Project vm ->
                    EntityList.GroupView.initKeyed appViewModel vm

                Todo vm ->
                    Todo.View.initKeyed vm
    in
        Html.Keyed.node "div"
            [ class "entity-list focusable-list"
            , Model.OnEntityListKeyDown entityList |> onKeyDown
            ]
            (vmList
                .|> createEntityView
            )
