module ViewModel exposing (..)

import Context
import Dict exposing (Dict)
import Document exposing (Id)
import Entity
import ExclusiveMode
import OldGroupEntity.ViewModel exposing (DocumentWithNameViewModel)
import Html exposing (Attribute)
import Model exposing (Msg)
import Project
import Set exposing (Set)
import Time exposing (Time)
import Todo
import Todo.Form
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Model exposing (ViewType(..))
import View.Shared exposing (SharedViewModel)


type alias Model =
    { contexts : OldGroupEntity.ViewModel.ViewModel
    , projects : OldGroupEntity.ViewModel.ViewModel
    , viewName : String
    , mainViewType : ViewType
    , header : { backgroundColor : String }
    , now : Time
    , getMaybeEditTodoFormForTodo : Todo.Model -> Maybe Todo.Form.Model
    , projectByIdDict : Dict Id Project.Model
    , contextByIdDict : Dict Id Context.Model
    , selectedEntityIdSet : Set Document.Id
    }


create : Model.Model -> Model
create model =
    let
        contextsVM =
            OldGroupEntity.ViewModel.contexts model

        projectsVM =
            OldGroupEntity.ViewModel.projects model

        mainViewType =
            model.mainViewType

        ( viewName, headerBackgroundColor ) =
            getViewInfo mainViewType projectsVM contextsVM

        sharedViewModel =
            View.Shared.createSharedViewModel model

        editMode =
            Model.getEditMode model

        now =
            Model.getNow model

        getMaybeEditTodoFormForTodo =
            \todo ->
                case editMode of
                    ExclusiveMode.EditTodo form ->
                        if Document.hasId form.id todo then
                            Just form
                        else
                            Nothing

                    _ ->
                        Nothing
    in
        { contexts = contextsVM
        , projects = projectsVM
        , viewName = viewName
        , mainViewType = mainViewType
        , header = { backgroundColor = headerBackgroundColor }
        , now = now
        , selectedEntityIdSet = model.selectedEntityIdSet
        , projectByIdDict = Model.getProjectsAsIdDict model
        , contextByIdDict = Model.getContextsAsIdDict model
        , getMaybeEditTodoFormForTodo = getMaybeEditTodoFormForTodo
        }


getViewInfo mainViewType projectsVM contextsVM =
    let
        entityById id =
            List.find (.id >> equals id)

        appHeaderInfoById id =
            entityById id
                >>? (.appHeader)
                >>?= { name = "o_O", backgroundColor = sgtdBlue }
                >> (\{ name, backgroundColor } -> ( name, backgroundColor ))
    in
        case mainViewType of
            EntityListView viewType ->
                case viewType of
                    Entity.ContextsView ->
                        ( contextsVM.title, contextsVM.icon.color )

                    Entity.ContextView id ->
                        contextsVM.entityList |> appHeaderInfoById id

                    Entity.ProjectsView ->
                        ( projectsVM.title, projectsVM.icon.color )

                    Entity.ProjectView id ->
                        projectsVM.entityList |> appHeaderInfoById id

                    Entity.BinView ->
                        ( "Bin", sgtdBlue )

                    Entity.DoneView ->
                        ( "Done", sgtdBlue )

            SyncView ->
                ( "Custom Sync", sgtdBlue )


sgtdBlue =
    --paper-blue-a200
    "rgb(68, 138, 255)"
